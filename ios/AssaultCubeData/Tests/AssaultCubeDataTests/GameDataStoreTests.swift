import Foundation
import XCTest
@testable import AssaultCubeData

final class GameDataStoreTests: XCTestCase {
    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeValidGameData(at root: URL) throws {
        let files = [
            "config/font.cfg",
            "packages/misc/notexture.jpg",
            "packages/maps/official/ac_test.cgz",
            "packages/textures/test.jpg",
            "packages/models/test.md2",
            "packages/audio/test.ogg"
        ]
        for relative in files {
            let file = root.appendingPathComponent(relative)
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("test".utf8).write(to: file)
        }
    }

    func testValidationRequiresActualCorePaths() throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertFalse(GameDataStore.validate(directory: root).isValid)
        try makeValidGameData(at: root)
        XCTAssertTrue(GameDataStore.validate(directory: root).isValid)
    }

    func testFolderImportAndStorageUsage() throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let selected = root.appendingPathComponent("AssaultCube", isDirectory: true)
        try makeValidGameData(at: selected)
        let documents = root.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)

        let status = try GameDataStore(documentsDirectory: documents).importItem(at: selected)
        XCTAssertTrue(status.isValid)
        XCTAssertEqual(status.fileCount, 6)
        XCTAssertGreaterThan(status.byteCount, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: documents.appendingPathComponent("GameData/config/font.cfg").path))
    }

    func testResetLeavesUnrelatedSettingsUntouched() throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let documents = root.appendingPathComponent("Documents", isDirectory: true)
        let store = GameDataStore(documentsDirectory: documents)
        try makeValidGameData(at: store.gameDataDirectory)
        let settings = documents.appendingPathComponent("Settings/preferences.json")
        try FileManager.default.createDirectory(at: settings.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("keep".utf8).write(to: settings)

        try store.reset()
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.gameDataDirectory.path))
        XCTAssertEqual(try Data(contentsOf: settings), Data("keep".utf8))
    }

    func testInvalidImportDoesNotReplaceExistingData() throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let documents = root.appendingPathComponent("Documents", isDirectory: true)
        let store = GameDataStore(documentsDirectory: documents)
        try makeValidGameData(at: store.gameDataDirectory)
        let marker = store.gameDataDirectory.appendingPathComponent("packages/keep.txt")
        try Data("old".utf8).write(to: marker)
        let invalid = root.appendingPathComponent("NotGameData", isDirectory: true)
        try FileManager.default.createDirectory(at: invalid, withIntermediateDirectories: true)

        XCTAssertThrowsError(try store.importItem(at: invalid))
        XCTAssertEqual(try Data(contentsOf: marker), Data("old".utf8))
    }
}
