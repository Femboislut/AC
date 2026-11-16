import GLKit
import UIKit

final class EngineViewController: GLKViewController {
    private var context: EAGLContext?
    private var lifecycleObservers: [NSObjectProtocol] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let context = EAGLContext(api: .openGLES2) else {
            fatalError("OpenGLES2 context could not be created")
        }
        self.context = context

        let glkView = GLKView(frame: view.bounds, context: context)
        glkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        glkView.drawableColorFormat = .RGBA8888
        glkView.drawableDepthFormat = .Format16
        glkView.drawableStencilFormat = .Format8
        view = glkView

        preferredFramesPerSecond = 60
        EngineBridge.startEngine()
        installApplicationLifecycleObservers()
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        EngineBridge.renderFrame(withWidth: view.drawableWidth, height: view.drawableHeight)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isPaused = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isPaused = true
    }

    private func installApplicationLifecycleObservers() {
        let center = NotificationCenter.default
        lifecycleObservers.append(center.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isPaused = true
        })
        lifecycleObservers.append(center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isPaused = false
        })
    }

    deinit {
        lifecycleObservers.forEach(NotificationCenter.default.removeObserver)
        EngineBridge.shutdown()
        if let context, EAGLContext.current() === context {
            EAGLContext.setCurrent(nil)
        }
    }
}
