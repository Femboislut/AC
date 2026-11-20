import UIKit

@_silgen_name("ac_ios_toggle_keyboard")
private func acEngineToggleKeyboard()
@_silgen_name("ac_ios_toggle_input_mode")
private func acEngineToggleInputMode()
@_silgen_name("ac_ios_virtual_key")
private func acEngineVirtualKey(_ key: Int32, _ down: Int32)
@_silgen_name("ac_ios_virtual_mouse")
private func acEngineVirtualMouse(_ down: Int32)

private final class ACKeyboardOverlayView: UIView {
    private let button = UIButton(type: .system)
    private let modeButton = UIButton(type: .system)
    private let joystick = UIView()
    private let joystickKnob = UIView()
    private var controlButtons: [UIButton] = []
    private var xPercent: CGFloat = 92
    private var yPercent: CGFloat = 7
    private var buttonSize: CGFloat = 48
    private var keyboardVisible = false
    private var menuMode = true
    private var pressedDirections: Set<Int32> = []

    private let keyW: Int32 = 119
    private let keyA: Int32 = 97
    private let keyS: Int32 = 115
    private let keyD: Int32 = 100

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        style(button, titleSize: 15)
        button.addTarget(self, action: #selector(toggleKeyboard), for: .touchUpInside)
        addSubview(button)

        style(modeButton, titleSize: 15)
        modeButton.addTarget(self, action: #selector(toggleInputMode), for: .touchUpInside)
        addSubview(modeButton)

        joystick.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        joystick.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        joystick.layer.borderWidth = 2
        joystick.layer.cornerRadius = 64
        joystick.isHidden = true
        joystick.isExclusiveTouch = false
        addSubview(joystick)

        joystickKnob.backgroundColor = UIColor.white.withAlphaComponent(0.58)
        joystickKnob.layer.cornerRadius = 25
        joystickKnob.isUserInteractionEnabled = false
        joystick.addSubview(joystickKnob)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleJoystickPan(_:)))
        pan.maximumNumberOfTouches = 1
        joystick.addGestureRecognizer(pan)

        addKeyButton("FIRE", key: -1, size: 70)
        addKeyButton("JUMP", key: 32, size: 54)
        addKeyButton("CROUCH", key: 0x400000E1, size: 52)
        addKeyButton("RELOAD", key: 114, size: 48)
        addKeyButton("NADE", key: 103, size: 48)
        addKeyButton("PREV", key: 113, size: 48)
        refreshTitle()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }

    private func style(_ target: UIButton, titleSize: CGFloat) {
        target.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        target.setTitleColor(.white, for: .normal)
        target.titleLabel?.font = .systemFont(ofSize: titleSize, weight: .bold)
        target.layer.cornerRadius = 12
        target.layer.borderWidth = 1
        target.layer.borderColor = UIColor.white.withAlphaComponent(0.32).cgColor
        target.isExclusiveTouch = false
    }

    private func addKeyButton(_ title: String, key: Int, size: CGFloat) {
        let control = UIButton(type: .system)
        style(control, titleSize: 11)
        control.setTitle(title, for: .normal)
        control.layer.cornerRadius = size / 2
        control.tag = key
        control.addTarget(self, action: #selector(controlDown(_:)), for: .touchDown)
        for event: UIControl.Event in [.touchUpInside, .touchUpOutside, .touchCancel] {
            control.addTarget(self, action: #selector(controlUp(_:)), for: event)
        }
        control.isHidden = true
        addSubview(control)
        controlButtons.append(control)
    }

    func configure(x: CGFloat, y: CGFloat, size: CGFloat, visible: Bool, menuMode: Bool) {
        xPercent = min(max(x, 0), 100)
        yPercent = min(max(y, 0), 100)
        buttonSize = min(max(size, 32), 80)
        keyboardVisible = visible
        setMenuMode(menuMode)
        refreshTitle()
        setNeedsLayout()
    }

    func setMenuMode(_ enabled: Bool) {
        menuMode = enabled
        joystick.isHidden = enabled
        controlButtons.forEach { $0.isHidden = enabled }
        if enabled { releaseAllDirections() }
        refreshTitle()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = buttonSize * 2.15
        let height = buttonSize
        let margin: CGFloat = 7
        let availableWidth = max(bounds.width - width - margin * 2, 0)
        let availableHeight = max(bounds.height - height - margin * 2, 0)
        let x = margin + availableWidth * xPercent / 100
        let y = margin + availableHeight * yPercent / 100
        button.frame = CGRect(x: x, y: y, width: width, height: height)
        let modeWidth = max(buttonSize * 1.85, 88)
        modeButton.frame = CGRect(x: max(margin, x - modeWidth - 8), y: y,
                                  width: modeWidth, height: height)

        let joystickSize: CGFloat = 128
        joystick.frame = CGRect(x: 22, y: max(18, bounds.height - joystickSize - 22),
                                width: joystickSize, height: joystickSize)
        joystick.layer.cornerRadius = joystickSize / 2
        joystickKnob.frame = CGRect(x: 39, y: 39, width: 50, height: 50)

        let fire = controlButtons[0]
        let jump = controlButtons[1]
        let crouch = controlButtons[2]
        let reload = controlButtons[3]
        let nade = controlButtons[4]
        let previous = controlButtons[5]
        fire.frame = CGRect(x: bounds.width - 94, y: bounds.height - 154, width: 76, height: 76)
        jump.frame = CGRect(x: bounds.width - 180, y: bounds.height - 146, width: 58, height: 58)
        crouch.frame = CGRect(x: bounds.width - 104, y: bounds.height - 72, width: 54, height: 54)
        reload.frame = CGRect(x: bounds.width - 170, y: bounds.height - 76, width: 50, height: 50)
        nade.frame = CGRect(x: bounds.width - 232, y: bounds.height - 142, width: 50, height: 50)
        previous.frame = CGRect(x: bounds.width - 232, y: bounds.height - 76, width: 50, height: 50)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else { return nil }
        let candidates: [UIView] = [button, modeButton, joystick] + controlButtons.reversed()
        for view in candidates where !view.isHidden {
            let local = view.convert(point, from: self)
            if view.bounds.contains(local) {
                return view.hitTest(local, with: event) ?? view
            }
        }
        return nil
    }

    @objc private func toggleKeyboard() { acEngineToggleKeyboard() }
    @objc private func toggleInputMode() { acEngineToggleInputMode() }

    @objc private func controlDown(_ sender: UIButton) {
        if sender.tag == -1 { acEngineVirtualMouse(1) }
        else { acEngineVirtualKey(Int32(sender.tag), 1) }
    }

    @objc private func controlUp(_ sender: UIButton) {
        if sender.tag == -1 { acEngineVirtualMouse(0) }
        else { acEngineVirtualKey(Int32(sender.tag), 0) }
    }

    @objc private func handleJoystickPan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: joystick)
        let center = CGPoint(x: joystick.bounds.midX, y: joystick.bounds.midY)
        var dx = point.x - center.x
        var dy = point.y - center.y
        let length = max(sqrt(dx * dx + dy * dy), 1)
        let radius: CGFloat = 39
        if length > radius {
            dx = dx / length * radius
            dy = dy / length * radius
        }
        joystickKnob.center = CGPoint(x: center.x + dx, y: center.y + dy)

        if gesture.state == .began || gesture.state == .changed {
            var next: Set<Int32> = []
            if dy < -13 { next.insert(keyW) }
            if dy > 13 { next.insert(keyS) }
            if dx < -13 { next.insert(keyA) }
            if dx > 13 { next.insert(keyD) }
            updateDirections(next)
        } else if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            joystickKnob.center = center
            releaseAllDirections()
        }
    }

    private func updateDirections(_ next: Set<Int32>) {
        for key in pressedDirections.subtracting(next) { acEngineVirtualKey(key, 0) }
        for key in next.subtracting(pressedDirections) { acEngineVirtualKey(key, 1) }
        pressedDirections = next
    }

    private func releaseAllDirections() {
        for key in pressedDirections { acEngineVirtualKey(key, 0) }
        pressedDirections.removeAll()
        joystickKnob.center = CGPoint(x: joystick.bounds.midX, y: joystick.bounds.midY)
    }

    private func refreshTitle() {
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
    DispatchQueue.main.async { ACKeyboardOverlay.overlay?.setMenuMode(ACKeyboardOverlay.menuMode) }
}

@_cdecl("ac_ios_keyboard_overlay_update")
public func acIOSKeyboardOverlayUpdate(_ enabled: Int32, _ inputActive: Int32,
                                      _ keyboardVisible: Int32, _ x: Float, _ y: Float,
                                      _ size: Float) {
    ACKeyboardOverlay.update(enabled: enabled != 0, inputActive: inputActive != 0,
                              visible: keyboardVisible != 0, x: CGFloat(x), y: CGFloat(y),
                              size: CGFloat(size))
}
