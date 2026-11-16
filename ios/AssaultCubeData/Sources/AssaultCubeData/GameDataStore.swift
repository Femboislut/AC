import Foundation
import ZIPFoundation

/// Validated installation data is stored separately from app preferences/configuration.
public struct GameDataStatus: Equatable, Sendable {
    public let isValid: Bool
    public let fileCount: Int
    public let byteCount: Int64
    public let missingRequirements: [String]

    public init(isValid: Bool, fileCount: Int, byteCount: Int64, missingRequirements: [String]) {
        self.isValid = isValid
        self.fileCount = fileCount
        self.byteCount = byteCount
        self.missingRequirements = missingRequirements
    }
}

public enum GameDataError: LocalizedError {
    case unsupportedInput
    case invalidArchive(String)
    case unsafeArchiveEntry(String)
    case archiveTooLarge
    case invalidGameData([String])
    case noGameDataFound

    public var errorDescription: String? {
        switch self {
        case .unsupportedInput:
            return "Choose an AssaultCube data folder or a ZIP archive."
        case .invalidArchive(let detail):
            return "The ZIP archive could not be imported: \(detail)"
        case .unsafeArchiveEntry(let path):
            return "The ZIP contains an unsafe path or link and was rejected: \(path)"
        case .archiveTooLarge:
            return "The ZIP is too large or contains too many entries to import safely."
        case .invalidGameData(let missing):
            return "This does not look like complete AssaultCube game data. Missing: \(missing.joined(separator: ", "))."
        case .noGameDataFound:
            return "No AssaultCube data root was found. Select the folder containing config and packages, or a ZIP containing those folders."
        }
    }
}

/// Import, validate, inspect, and reset game data without touching app settings.
/// Call from a background task for large folders/archives.
public struct GameDataStore: Sendable {
    public static let directoryName = "GameData"
    private static let maximumArchiveBytes: UInt64 = 2 * 1024 * 1024 * 1024
    private static let maximumArchiveEntries = 100_000

    private let documentsDirectory: URL
    private let fileManager: FileManager

    public init(documentsDirectory: URL, fileManager: FileManager = .default) {
        self.documentsDirectory = documentsDirectory
        self.fileManager = fileManager
    }

    public var gameDataDirectory: URL {
        documentsDirectory.appendingPathComponent(Self.directoryName, isDirectory: true)
    }

    /// URL should be obtained from UIDocumentPicker. Security-scoped access is started
    /// here and held only while the import copy is made.
    public func importItem(at sourceURL: URL) throws -> GameDataStatus {
        let hasScope = sourceURL.startAccessingSecurityScopedResource()
        defer { if hasScope { sourceURL.stopAccessingSecurityScopedResource() } }

        let staging = fileManager.temporaryDirectory
            .appendingPathComponent("ac-import-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: staging) }

        if sourceURL.pathExtension.lowercased() == "zip" {
            try extractArchive(at: sourceURL, into: staging)
        } else {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                throw GameDataError.unsupportedInput
            }
            try copyTreeSafely(from: sourceURL, to: staging.appendingPathComponent("selection", isDirectory: true))
        }

        guard let dataRoot = findDataRoot(in: staging) else { throw GameDataError.noGameDataFound }
        let validation = Self.validate(directory: dataRoot, fileManager: fileManager)
        guard validation.isValid else { throw GameDataError.invalidGameData(validation.missingRequirements) }

        let prepared = staging.appendingPathComponent("prepared", isDirectory: true)
        try fileManager.createDirectory(at: prepared, withIntermediateDirectories: true)
        for name in ["config", "packages", "mods"] {
            let item = dataRoot.appendingPathComponent(name, isDirectory: true)
            if fileManager.fileExists(atPath: item.path) {
                try copyTreeSafely(from: item, to: prepared.appendingPathComponent(name, isDirectory: true))
            }
        }

        try replaceGameData(with: prepared)
        return Self.validate(directory: gameDataDirectory, fileManager: fileManager)
    }

    public func status() -> GameDataStatus {
        Self.validate(directory: gameDataDirectory, fileManager: fileManager)
    }

    /// Reset only imported game assets. Application preferences and other Documents
    /// content are deliberately not removed.
    public func reset() throws {
        guard fileManager.fileExists(atPath: gameDataDirectory.path) else { return }
        try fileManager.removeItem(at: gameDataDirectory)
    }

    public static func validate(directory: URL, fileManager: FileManager = .default) -> GameDataStatus {
        let requiredFiles = [
            "config/font.cfg",
            "packages/misc/notexture.jpg"
        ]
        var missing = requiredFiles.filter {
            !fileManager.fileExists(atPath: directory.appendingPathComponent($0).path)
        }
        let mapsURL = directory.appendingPathComponent("packages/maps/official", isDirectory: true)
        let hasMap: Bool
        if let entries = try? fileManager.contentsOfDirectory(at: mapsURL, includingPropertiesForKeys: nil) {
            hasMap = entries.contains { $0.pathExtension.lowercased() == "cgz" }
        } else {
            hasMap = false
        }
        if !hasMap { missing.append("packages/maps/official/*.cgz") }
        for requiredDirectory in ["packages/textures", "packages/models", "packages/audio"] {
            var isDirectory: ObjCBool = false
            if !fileManager.fileExists(atPath: directory.appendingPathComponent(requiredDirectory).path, isDirectory: &isDirectory) || !isDirectory.boolValue {
                missing.append(requiredDirectory + "/")
            }
        }

        let (fileCount, byteCount) = storageUsage(at: directory, fileManager: fileManager)
        return GameDataStatus(isValid: missing.isEmpty, fileCount: fileCount, byteCount: byteCount, missingRequirements: missing)
    }

    private func findDataRoot(in directory: URL) -> URL? {
        var candidates = [directory]
        if let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            while let url = enumerator.nextObject() as? URL {
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                if values?.isSymbolicLink == true { enumerator.skipDescendants(); continue }
                if values?.isDirectory == true { candidates.append(url) }
            }
        }
        return candidates.first { Self.validate(directory: $0, fileManager: fileManager).isValid }
    }

    private func extractArchive(at archiveURL: URL, into destination: URL) throws {
        guard let archive = Archive(url: archiveURL, accessMode: .read) else {
            throw GameDataError.invalidArchive("It is not a readable ZIP file.")
        }
        var expanded: UInt64 = 0
        var count = 0
        do {
            for entry in archive {
                count += 1
                let path = entry.path
                guard count <= Self.maximumArchiveEntries,
                      entry.uncompressedSize <= Self.maximumArchiveBytes,
                      expanded <= Self.maximumArchiveBytes - entry.uncompressedSize else {
                    throw GameDataError.archiveTooLarge
                }
                expanded += entry.uncompressedSize
                guard isSafeArchivePath(path), entry.type != .symlink else {
                    throw GameDataError.unsafeArchiveEntry(path)
                }
                let output = destination.appendingPathComponent(path)
                if entry.type == .directory {
                    try fileManager.createDirectory(at: output, withIntermediateDirectories: true)
                } else if entry.type == .file {
                    try fileManager.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try archive.extract(entry, to: output, skipCRC32: false)
                }
            }
        } catch let error as GameDataError {
            throw error
        } catch {
            throw GameDataError.invalidArchive(error.localizedDescription)
        }
    }

    private func isSafeArchivePath(_ path: String) -> Bool {
        guard !path.isEmpty, !path.hasPrefix("/"), !path.contains("\\"), !path.contains(":"),
              !path.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return false }
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        return components.allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }

    private func copyTreeSafely(from source: URL, to destination: URL) throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: source.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw GameDataError.unsupportedInput
        }
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        guard let enumerator = fileManager.enumerator(
            at: source,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { throw GameDataError.invalidGameData(["selected folder could not be read"]) }

        for case let item as URL in enumerator {
            let values = try item.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            let relative = item.path.replacingOccurrences(of: source.path + "/", with: "")
            guard !relative.hasPrefix("/") && !relative.split(separator: "/").contains("..") else {
                throw GameDataError.unsafeArchiveEntry(relative)
            }
            guard values.isSymbolicLink != true else {
                enumerator.skipDescendants()
                continue
            }
            let target = destination.appendingPathComponent(relative)
            if values.isDirectory == true {
                try fileManager.createDirectory(at: target, withIntermediateDirectories: true)
            } else {
                try fileManager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fileManager.copyItem(at: item, to: target)
            }
        }
    }

    private func replaceGameData(with prepared: URL) throws {
        let parent = gameDataDirectory.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        let backup = parent.appendingPathComponent("GameData-backup-\(UUID().uuidString)", isDirectory: true)
        let hadOldData = fileManager.fileExists(atPath: gameDataDirectory.path)
        if hadOldData { try fileManager.moveItem(at: gameDataDirectory, to: backup) }
        do {
            try fileManager.moveItem(at: prepared, to: gameDataDirectory)
            if hadOldData { try? fileManager.removeItem(at: backup) }
        } catch {
            if hadOldData { try? fileManager.moveItem(at: backup, to: gameDataDirectory) }
            throw error
        }
    }

    private static func storageUsage(at root: URL, fileManager: FileManager) -> (Int, Int64) {
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return (0, 0) }
        var count = 0
        var bytes: Int64 = 0
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]),
                  values.isRegularFile == true, values.isSymbolicLink != true else { continue }
            count += 1
            bytes += Int64(values.fileSize ?? 0)
        }
        return (count, bytes)
    }
}
