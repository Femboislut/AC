import SwiftUI
import UniformTypeIdentifiers
import AssaultCubeData

@main
struct AssaultCubeDataApp: App {
    var body: some Scene {
        WindowGroup {
            GameDataView(store: GameDataStore(documentsDirectory: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]))
        }
    }
}

private struct GameDataView: View {
    let store: GameDataStore
    @State private var status: GameDataStatus
    @State private var showingImporter = false
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var showResetConfirmation = false
    @AppStorage("touchSensitivity") private var touchSensitivity = 1.0

    init(store: GameDataStore) {
        self.store = store
        _status = State(initialValue: store.status())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game data") {
                    Label(status.isValid ? "Valid game data found" : "Game data not installed", systemImage: status.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(status.isValid ? .green : .orange)
                    if status.isValid {
                        LabeledContent("Files", value: "\(status.fileCount)")
                        LabeledContent("Storage", value: ByteCountFormatter.string(fromByteCount: status.byteCount, countStyle: .file))
                    } else {
                        Text("Required data is read from the AssaultCube game directory. The app extracts data from Windows installers without executing Windows programs or DLLs.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if !status.missingRequirements.isEmpty {
                            Text("Missing: \(status.missingRequirements.joined(separator: ", "))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button(status.isValid ? "Replace / Import Game Data" : "Import Game Data") { showingImporter = true }
                        .disabled(isWorking)
                    if status.isValid {
                        Button("Reset Imported Game Data", role: .destructive) { showResetConfirmation = true }
                            .disabled(isWorking)
                    }
                }

                Section("Touch preference") {
                    VStack(alignment: .leading) {
                        Text("Look sensitivity: \(touchSensitivity, specifier: "%.2f")")
                        Slider(value: $touchSensitivity, in: 0.25...3.0)
                    }
                    Text("This preference is saved on this device. It is not connected to gameplay until the engine's input layer is ported.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Port status") {
                    Label("Game engine is not integrated in this app yet", systemImage: "hammer")
                        .foregroundStyle(.orange)
                    Text("This app currently provides the native data-management groundwork only. It does not launch AssaultCube gameplay. The desktop OpenGL renderer, SDL app lifecycle, audio, and input still require an iOS port.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("AssaultCube iOS")
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.zip, .folder, UTType(filenameExtension: "exe") ?? .data], allowsMultipleSelection: false, onCompletion: handleImport)
            .confirmationDialog("Remove imported game data?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                Button("Reset Game Data", role: .destructive, action: resetData)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Only Documents/GameData will be removed. Other app settings and files are preserved.")
            }
            .alert("Game data", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
            .overlay {
                if isWorking {
                    ProgressView("Importing…")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else {
            if case .failure(let error) = result { errorMessage = error.localizedDescription }
            return
        }
        isWorking = true
        Task.detached(priority: .userInitiated) {
            do {
                let newStatus = try store.importItem(at: url)
                await MainActor.run { status = newStatus; isWorking = false }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isWorking = false }
            }
        }
    }

    private func resetData() {
        do {
            try store.reset()
            status = store.status()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
