import UIKit
import CoreMotion

@_silgen_name("ac_ios_toggle_keyboard")
private func acEngineToggleKeyboard()
@_silgen_name("ac_ios_toggle_input_mode")
private func acEngineToggleInputMode()
@_silgen_name("ac_ios_virtual_key")
private func acEngineVirtualKey(_ key: Int32, _ down: Int32)
@_silgen_name("ac_ios_virtual_mouse")
private func acEngineVirtualMouse(_ down: Int32)
@_silgen_name("ac_ios_gyro_motion")
private func acEngineGyroMotion(_ dx: Float, _ dy: Float)

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
    private var hudEnabled = true
    private var hudScale: CGFloat = 1
    private let motionManager = CMMotionManager()
    private var gyroEnabled = false
    private var gyroSensitivity: Double = 1
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
        addKeyButton("PRI", key: 49, size: 46)
        addKeyButton("SEC", key: 50, size: 46)
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

    func configure(keyboardEnabled: Bool, x: CGFloat, y: CGFloat, size: CGFloat, visible: Bool, menuMode: Bool, hudEnabled: Bool, hudScale: CGFloat) {
        xPercent = min(max(x, 0), 100)
        yPercent = min(max(y, 0), 100)
        buttonSize = min(max(size, 32), 80)
        button.isHidden = !keyboardEnabled
        keyboardVisible = visible
        self.hudEnabled = hudEnabled
        self.hudScale = min(max(hudScale, 0.6), 1.4)
        setMenuMode(menuMode)
        refreshTitle()
        setNeedsLayout()
    }

    func setMenuMode(_ enabled: Bool) {
        menuMode = enabled
        joystick.isHidden = enabled || !hudEnabled
        controlButtons.forEach { $0.isHidden = enabled || !hudEnabled }
        if enabled { releaseAllDirections() }
        refreshGyroscope()
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

        let scale = hudScale
        let joystickSize: CGFloat = 128 * scale
        joystick.frame = CGRect(x: 22 * scale, y: max(18 * scale, bounds.height - joystickSize - 22 * scale),
                                width: joystickSize, height: joystickSize)
        joystick.layer.cornerRadius = joystickSize / 2
        joystickKnob.frame = CGRect(x: 39 * scale, y: 39 * scale, width: 50 * scale, height: 50 * scale)

        let fire = controlButtons[0]
        let jump = controlButtons[1]
        let crouch = controlButtons[2]
        let reload = controlButtons[3]
        let nade = controlButtons[4]
        let previous = controlButtons[5]
        let primary = controlButtons[6]
        let secondary = controlButtons[7]
        fire.frame = CGRect(x: bounds.width - 94 * scale, y: bounds.height - 154 * scale, width: 76 * scale, height: 76 * scale)
        jump.frame = CGRect(x: bounds.width - 180 * scale, y: bounds.height - 146 * scale, width: 58 * scale, height: 58 * scale)
        crouch.frame = CGRect(x: bounds.width - 104 * scale, y: bounds.height - 72 * scale, width: 54 * scale, height: 54 * scale)
        reload.frame = CGRect(x: bounds.width - 170 * scale, y: bounds.height - 76 * scale, width: 50 * scale, height: 50 * scale)
        nade.frame = CGRect(x: bounds.width - 232 * scale, y: bounds.height - 142 * scale, width: 50 * scale, height: 50 * scale)
        previous.frame = CGRect(x: bounds.width - 232 * scale, y: bounds.height - 76 * scale, width: 50 * scale, height: 50 * scale)
        primary.frame = CGRect(x: bounds.width - 292 * scale, y: bounds.height - 142 * scale, width: 46 * scale, height: 46 * scale)
        secondary.frame = CGRect(x: bounds.width - 292 * scale, y: bounds.height - 82 * scale, width: 46 * scale, height: 46 * scale)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else { return nil }
        let candidates: [UIView] = [button, modeButton, joystick] + controlButtons.reversed().map { $0 as UIView }
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

    func setHUD(enabled: Bool, scale: CGFloat) {
        hudEnabled = enabled
        hudScale = min(max(scale, 0.6), 1.4)
        joystick.isHidden = menuMode || !hudEnabled
        controlButtons.forEach { $0.isHidden = menuMode || !hudEnabled }
        if !hudEnabled { releaseAllDirections() }
        setNeedsLayout()
    }

    func configureGyroscope(enabled: Bool, sensitivity: Double) {
        gyroEnabled = enabled
        gyroSensitivity = min(max(sensitivity, 0.1), 3.0)
        refreshGyroscope()
    }

    private func refreshGyroscope() {
        let shouldRun = gyroEnabled && !menuMode && motionManager.isGyroAvailable
        if shouldRun && !motionManager.isGyroActive {
            motionManager.gyroUpdateInterval = 1.0 / 60.0
            motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
                guard let self, !self.menuMode, let rate = data?.rotationRate else { return }
                let orientation = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }.first?.interfaceOrientation ?? .landscapeRight
                var yaw = rate.y
                var pitch = rate.x
                if orientation == .landscapeRight { yaw = -rate.y; pitch = -rate.x }
                else if orientation == .portrait { yaw = rate.z; pitch = rate.x }
                let factor = self.gyroSensitivity * 600.0 / 60.0
                acEngineGyroMotion(Float(yaw * factor), Float(pitch * factor))
            }
        } else if !shouldRun && motionManager.isGyroActive {
            motionManager.stopGyroUpdates()
        }
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
    static var menuMode = true
    static var hudEnabled = true
    static var hudScale: CGFloat = 1
    static var gyroEnabled = false
    static var gyroSensitivity: Double = 1

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

            if overlay == nil || overlay?.superview !== root {
                overlay?.removeFromSuperview()
                let newOverlay = ACKeyboardOverlayView(frame: root.bounds)
                root.addSubview(newOverlay)
                overlay = newOverlay
            }
            overlay?.frame = root.bounds
            overlay?.configure(keyboardEnabled: enabled, x: x, y: y, size: size, visible: visible, menuMode: menuMode,
                               hudEnabled: hudEnabled, hudScale: hudScale)
            overlay?.configureGyroscope(enabled: gyroEnabled, sensitivity: gyroSensitivity)
            root.bringSubviewToFront(overlay!)
        }
    }
}

@_cdecl("ac_ios_input_mode_update")
public func acIOSInputModeUpdate(_ menuMode: Int32) {
    ACKeyboardOverlay.menuMode = menuMode != 0
    DispatchQueue.main.async { ACKeyboardOverlay.overlay?.setMenuMode(ACKeyboardOverlay.menuMode) }
}

@_cdecl("ac_ios_touch_hud_update")
public func acIOSTouchHUDUpdate(_ enabled: Int32, _ scale: Float) {
    ACKeyboardOverlay.hudEnabled = enabled != 0
    ACKeyboardOverlay.hudScale = CGFloat(scale)
    DispatchQueue.main.async { ACKeyboardOverlay.overlay?.setHUD(
        enabled: ACKeyboardOverlay.hudEnabled, scale: ACKeyboardOverlay.hudScale) }
}

@_cdecl("ac_ios_gyro_config_update")
public func acIOSGyroConfigUpdate(_ enabled: Int32, _ sensitivity: Float) {
    ACKeyboardOverlay.gyroEnabled = enabled != 0
    ACKeyboardOverlay.gyroSensitivity = Double(sensitivity)
    DispatchQueue.main.async { ACKeyboardOverlay.overlay?.configureGyroscope(
        enabled: ACKeyboardOverlay.gyroEnabled, sensitivity: ACKeyboardOverlay.gyroSensitivity) }
}

@_cdecl("ac_ios_keyboard_overlay_update")
public func acIOSKeyboardOverlayUpdate(_ enabled: Int32, _ inputActive: Int32,
                                      _ keyboardVisible: Int32, _ x: Float, _ y: Float,
                                      _ size: Float) {
    ACKeyboardOverlay.update(enabled: enabled != 0, inputActive: inputActive != 0,
                              visible: keyboardVisible != 0, x: CGFloat(x), y: CGFloat(y),
                              size: CGFloat(size))
}
