// ios/AssaultCubeApp/EngineViewController.swift
import UIKit
import GLKit

final class EngineViewController: UIViewController {
    private var glkView: GLKView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let context = EAGLContext(api: .openGLES3) ?? EAGLContext(api: .openGLES2)
        guard let context else { fatalError("No OpenGL ES context") }

        let newGLKView = GLKView(frame: view.bounds, context: context)
        newGLKView.drawableColorFormat = .RGBA8888
        newGLKView.drawableDepthFormat = .format24
        newGLKView.isMultipleTouchEnabled = true
        glkView = newGLKView
        view.addSubview(newGLKView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        glkView?.frame = view.bounds
    }
}
