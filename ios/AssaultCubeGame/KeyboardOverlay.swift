import UIKit

@_silgen_name("ac_ios_toggle_keyboard")
private func acEngineToggleKeyboard()

@_silgen_name("ac_ios_toggle_input_mode")
private func acEngineToggleInputMode()

private final class ACKeyboardOverlayView: UIView {
    private let button = UIButton(type: .system)
    private let modeButton = UIButton(type: .system)
    private var menuMode = true
    private var xPercent: CGFloat = 92
    private var yPercent: CGFloat = 7
    private var buttonSize: CGFloat = 48
    private var keyboardVisible = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        button.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
        button.addTarget(self, action: #selector(toggleKeyboard), for: .touchUpInside)
        addSubview(button)
        modeButton.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        modeButton.setTitleColor(.white, for: .normal)
        modeButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        modeButton.layer.cornerRadius = 12
        modeButton.layer.borderWidth = 1
        modeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
        modeButton.addTarget(self, action: #selector(toggleInputMode), for: .touchUpInside)
        addSubview(modeButton)
        refreshTitle()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }

    func configure(x: CGFloat, y: CGFloat, size: CGFloat, visible: Bool, menuMode: Bool) {
        xPercent = min(max(x, 0), 100)
        yPercent = min(max(y, 0), 100)
        buttonSize = min(max(size, 32), 80)
        keyboardVisible = visible
        self.menuMode = menuMode
        refreshTitle()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = buttonSize * 2.15
        let height = buttonSize
        let margin: CGFloat = 5
        let availableWidth = max(bounds.width - width - margin * 2, 0)
        let availableHeight = max(bounds.height - height - margin * 2, 0)
        let x = margin + availableWidth * xPercent / 100
        let y = margin + availableHeight * yPercent / 100
        button.frame = CGRect(x: x, y: y, width: width, height: height)
        let modeWidth = max(buttonSize * 1.85, 88)
        modeButton.frame = CGRect(x: max(margin, x - modeWidth - 8), y: y,
                                  width: modeWidth, height: height)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else { return nil }
        let keyboardPoint = button.convert(point, from: self)
        if button.bounds.contains(keyboardPoint) { return button.hitTest(keyboardPoint, with: event) }
        let modePoint = modeButton.convert(point, from: self)
        if modeButton.bounds.contains(modePoint) { return modeButton.hitTest(modePoint, with: event) }
        return nil
    }

    @objc private func toggleKeyboard() {
        acEngineToggleKeyboard()
    }

    @objc private func toggleInputMode() {
        acEngineToggleInputMode()
    }

    func refreshTitle() {
        button.setTitle(keyboardVisible ? "⌨ Hide" : "⌨ Show", for: .normal)
        button.accessibilityLabel = keyboardVisible ? "Hide keyboard" : "Show keyboard"
        modeButton.setTitle(menuMode ? "🎯 Aim" : "☰ Menu", for: .normal)
        modeButton.accessibilityLabel = menuMode ? "Enable aiming mode" : "Return to menu mode"
    }
}

private enum ACKeyboardOverlay {
    static var overlay: ACKeyboardOverlayView?

    private(set) static var menuMode = true

    static func update(enabled: Bool, inputActive: Bool, visible: Bool,
                       x: CGFloat, y: CGFloat, size: CGFloat) {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }),
                  let root = window.rootViewController?.view else {
                overlay?.removeFromSuperview()
                overlay = nil
                return
            }

            guard enabled else {
                overlay?.removeFromSuperview()
                overlay = nil
                return
            }

            if overlay == nil || overlay?.superview !== root {
                overlay?.removeFromSuperview()
                let newOverlay = ACKeyboardOverlayView(frame: root.bounds)
                root.addSubview(newOverlay)
                overlay = newOverlay
            }
            overlay?.frame = root.bounds
            overlay?.configure(x: x, y: y, size: size, visible: visible, menuMode: menuMode)
            root.bringSubviewToFront(overlay!)
        }
    }
}

@_cdecl("ac_ios_input_mode_update")
public func acIOSInputModeUpdate(_ menuMode: Int32) {
    ACKeyboardOverlay.menuMode = menuMode != 0
    DispatchQueue.main.async { ACKeyboardOverlay.overlay?.configure(
        x: 92, y: 7, size: 48, visible: false, menuMode: ACKeyboardOverlay.menuMode) }
}

@_cdecl("ac_ios_keyboard_overlay_update")
public func acIOSKeyboardOverlayUpdate(_ enabled: Int32, _ inputActive: Int32,
                                      _ keyboardVisible: Int32, _ x: Float, _ y: Float,
                                      _ size: Float) {
    ACKeyboardOverlay.update(enabled: enabled != 0, inputActive: inputActive != 0,
                              visible: keyboardVisible != 0, x: CGFloat(x), y: CGFloat(y),
                              size: CGFloat(size))
}
