import GLKit
import UIKit

final class EngineViewController: GLKViewController {
    private let context = EAGLContext(api: .openGLES2)

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let context else {
            fatalError("OpenGLES2 context could not be created")
        }

        let glkView = view as? GLKView ?? GLKView(frame: view.bounds, context: context)
        glkView.context = context
        glkView.drawableColorFormat = .RGBA8888
        glkView.drawableDepthFormat = .Format16
        glkView.drawableStencilFormat = .Format8

        self.view = glkView
        self.preferredFramesPerSecond = 60

        EngineBridge.initialize()
        EngineBridge.setViewport(width: Int(view.bounds.width), height: Int(view.bounds.height))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.becomeFirstResponder()
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        EngineBridge.renderFrame()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        TouchInput.handleBegan(touches, view: view)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        TouchInput.handleMoved(touches, view: view)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        TouchInput.handleEnded(touches, view: view)
    }

    deinit {
        EngineBridge.shutdown()
    }
}
