import Foundation
import UIKit
import UniformTypeIdentifiers
import AssaultCubeData

/// Runs before SDL initializes. The SDL UIKit application and its main run loop
/// already exist at this point, so this controller can safely collect game data
/// without creating a second UIApplication entry point.
@MainActor
private final class ACGameDataBootstrapController: UIViewController, UIDocumentPickerDelegate {
    private let store = GameDataStore(
        documentsDirectory: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    )
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let importButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .large)
    private(set) var finished = false
    private var importing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.055, green: 0.075, blue: 0.10, alpha: 1)

        titleLabel.text = "AssaultCube"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        detailLabel.text = "Game data is not installed yet. Select the official Windows installer (.exe), a ZIP archive, or an extracted game-data folder. The installer is extracted safely; Windows programs are never executed."
        detailLabel.font = .systemFont(ofSize: 17)
        detailLabel.textColor = UIColor(white: 0.88, alpha: 1)
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        importButton.setTitle("Import Game Data", for: .normal)
        importButton.titleLabel?.font = .systemFont(ofSize: 19, weight: .semibold)
        importButton.setTitleColor(.white, for: .normal)
        importButton.backgroundColor = UIColor(red: 0.12, green: 0.40, blue: 0.72, alpha: 1)
        importButton.layer.cornerRadius = 12
        importButton.contentEdgeInsets = UIEdgeInsets(top: 15, left: 28, bottom: 15, right: 28)
        importButton.addTarget(self, action: #selector(chooseInstaller), for: .touchUpInside)

        spinner.color = .white
        spinner.hidesWhenStopped = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel, importButton, spinner])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            detailLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 620),
            importButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 54)
        ])
    }

    @objc private func chooseInstaller() {
        guard !importing else { return }
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.item, .zip, .folder],
            asCopy: true
        )
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let source = urls.first, !importing else { return }
        importing = true
        importButton.isEnabled = false
        spinner.startAnimating()
        detailLabel.text = "Importing and validating game data. Keep AssaultCube open…"

        let store = self.store
        DispatchQueue.global(qos: .userInitiated).async { [weak self, store] in
            do {
                let status = try store.importItem(at: source)
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.spinner.stopAnimating()
                    self.importing = false
                    guard status.isValid else {
                        self.importButton.isEnabled = true
                        self.detailLabel.text = "The selected files did not contain a complete AssaultCube installation. Please choose the original installer or the correct game-data folder."
                        return
                    }
                    self.detailLabel.text = "Imported \(status.fileCount) files (\(ByteCountFormatter.string(fromByteCount: status.byteCount, countStyle: .file))). Starting AssaultCube…"
                    self.finished = true
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.spinner.stopAnimating()
                    self.importing = false
                    self.importButton.isEnabled = true
                    self.detailLabel.text = error.localizedDescription
                }
            }
        }
    }
}

/// C-callable preflight invoked by AssaultCube's SDL_main before any engine or
/// renderer initialization. Returns only after valid game data is installed.
@MainActor
@_cdecl("ac_ios_ensure_game_data")
public func ac_ios_ensure_game_data() -> Int32 {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let store = GameDataStore(documentsDirectory: documents)
    if store.status().isValid {
        return 0
    }

    let controller = ACGameDataBootstrapController()
    let window = UIWindow(frame: UIScreen.main.bounds)
    // SDL's own launch-screen window uses normal + 1; put the importer above it.
    window.windowLevel = UIWindow.Level.normal + 2
    window.rootViewController = controller
    window.makeKeyAndVisible()

    while !controller.finished {
        _ = RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
    }

    window.isHidden = true
    window.rootViewController = nil
    return 0
}
