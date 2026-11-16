import SwiftUI
import AssaultCubeData

struct GameDataView: View {
    let store: GameDataStore
    @State private var status: GameDataStatus
    @State private var importerPresented = false
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var confirmReset = false
    @AppStorage("ios.touch.sensitivity") private var touchSensitivity = 1.0

    init(store: GameDataStore) {
        self.store = store
        _status = State(initialValue: store.status())
    }

    var body: some View {
        Form {
            Section("Game data") {
                HStack {
                    Image(systemName: status.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(status.isValid ? .green : .orange)
                    Text(status.isValid ? "Valid AssaultCube game data detected" : "Game data not detected")
                }

                if status.isValid {
                    LabeledContent("Files", value: String(status.fileCount))
                    LabeledContent("Storage", value: ByteCountFormatter.string(fromByteCount: status.byteCount, countStyle: .file))
                } else {
                    Text("Expected AssaultCube package layout was not found.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if !status.missingRequirements.isEmpty {
                        Text("Missing: \(status.missingRequirements.joined(separator: ", "))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Button(status.isValid ? "Replace / Import Game Data" : "Import Game Data") {
                    importerPresented = true
                }
                .disabled(isImporting)

                if status.isValid {
                    Button("Reset Imported Game Data", role: .destructive) {
                        confirmReset = true
                    }
                    .disabled(isImporting)
                }
            }

            Section("Touch controls") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Look sensitivity: \(touchSensitivity, specifier: "%.2f")")
                    Slider(value: $touchSensitivity, in: 0.25...3.0)
                }
                Text("This value is stored locally for the iOS app settings layer. The actual game engine integration is still pending.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Current port status") {
                Label("Renderer, input, and app lifecycle are not yet implemented.", systemImage: "hammer.fill")
                    .foregroundStyle(.orange)
                Text("This screen is only the game-data import and validation layer. It is not a gameplay client.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .fileImporter(isPresented: $importerPresented, allowedContentTypes: [.zip, .folder], allowsMultipleSelection: false) { result in
            do {
                let urls = try result.get()
                guard let selected = urls.first else { return }
                isImporting = true
                do {
                    let newStatus = try store.importItem(at: selected)
                    status = newStatus
                } catch {
                    errorMessage = error.localizedDescription
                }
                isImporting = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .alert("Game data status", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog("Reset imported game data?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset Game Data", role: .destructive) {
                do {
                    try store.reset()
                    status = store.status()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Only the imported Documents/GameData content will be removed. App settings and unrelated files are preserved.")
        }
    }
}

#Preview {
    GameDataView(store: GameDataStore(documentsDirectory: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]))
}
