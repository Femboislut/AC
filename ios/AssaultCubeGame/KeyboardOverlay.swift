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

private final class ACKeyboardOverlayView: UIView, UIGestureRecognizerDelegate {
    private let button = UIButton(type: .system)
    private let modeButton = UIButton(type: .system)
    private let editButton = UIButton(type: .system)
    private let resetLayoutButton = UIButton(type: .system)
    private let joystick = UIView()
    private let joystickKnob = UIView()
    private var controlButtons: [UIButton] = []
    private var menuButtons: [UIButton] = []
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
    private var editingControls = false
    private var joystickPan: UIPanGestureRecognizer!
    private var dragStartCenter: CGPoint = .zero
    private let layoutDefaultsKey = "assaultcube.touch.layout.v1"

    private let keyW: Int32 = 119
    private let keyA: Int32 = 97
    private let keyS: Int32 = 115
    private let keyD: Int32 = 100

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isMultipleTouchEnabled = true
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        style(button, titleSize: 15)
        button.addTarget(self, action: #selector(toggleKeyboard), for: .touchUpInside)
        addSubview(button)

        style(modeButton, titleSize: 15)
        modeButton.addTarget(self, action: #selector(toggleInputMode), for: .touchUpInside)
        addSubview(modeButton)

        style(editButton, titleSize: 11)
        editButton.setTitle("EDIT HUD", for: .normal)
        editButton.addTarget(self, action: #selector(toggleEditingControls), for: .touchUpInside)
        addSubview(editButton)

        style(resetLayoutButton, titleSize: 11)
        resetLayoutButton.setTitle("RESET", for: .normal)
        resetLayoutButton.addTarget(self, action: #selector(resetControlLayout), for: .touchUpInside)
        resetLayoutButton.isHidden = true
        addSubview(resetLayoutButton)

        joystick.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        joystick.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        joystick.layer.borderWidth = 2
        joystick.layer.cornerRadius = 64
        joystick.isHidden = true
        joystick.isExclusiveTouch = false
        joystick.isMultipleTouchEnabled = true
        addSubview(joystick)

        joystickKnob.backgroundColor = UIColor.white.withAlphaComponent(0.58)
        joystickKnob.layer.cornerRadius = 25
        joystickKnob.isUserInteractionEnabled = false
        joystick.addSubview(joystickKnob)

        joystickPan = UIPanGestureRecognizer(target: self, action: #selector(handleJoystickPan(_:)))
        joystickPan.maximumNumberOfTouches = 1
        joystickPan.delegate = self
        joystick.addGestureRecognizer(joystickPan)
        let joystickDrag = UIPanGestureRecognizer(target: self, action: #selector(handleControlDrag(_:)))
        joystickDrag.delegate = self
        joystickDrag.cancelsTouchesInView = true
        joystick.addGestureRecognizer(joystickDrag)

        addKeyButton("FIRE", key: -1, size: 70)
        addKeyButton("JUMP", key: 32, size: 54)
        addKeyButton("CROUCH", key: 0x400000E1, size: 52)
        addKeyButton("RELOAD", key: 114, size: 48)
        addKeyButton("NADE", key: 103, size: 48)
        addKeyButton("PREV", key: 113, size: 48)
        addKeyButton("PRI", key: 49, size: 46)
        addKeyButton("SEC", key: 50, size: 46)
        addMenuButton("◀", key: 0x40000050)
        addMenuButton("▲", key: 0x40000052)
        addMenuButton("▼", key: 0x40000051)
        addMenuButton("▶", key: 0x4000004F)
        addMenuButton("OK", key: 13)
        addMenuButton("BACK", key: 27)
        refreshTitle()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }

    private func style(_ target: UIButton, titleSize: CGFloat) {
        target.backgroundColor = UIColor(red: 0.055, green: 0.085, blue: 0.14, alpha: 0.62)
        target.setTitleColor(.white, for: .normal)
        target.setTitleColor(UIColor.white.withAlphaComponent(0.72), for: .highlighted)
        target.titleLabel?.font = .systemFont(ofSize: titleSize, weight: .bold)
        target.titleLabel?.adjustsFontSizeToFitWidth = true
        target.titleLabel?.minimumScaleFactor = 0.72
        target.layer.cornerRadius = 14
        target.layer.cornerCurve = .continuous
        target.layer.borderWidth = 1.8
        target.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        target.layer.shadowColor = UIColor(red: 0.58, green: 0.83, blue: 0.96, alpha: 1).cgColor
        target.layer.shadowOpacity = 0.20
        target.layer.shadowRadius = 7
        target.layer.shadowOffset = CGSize(width: 0, height: 1)
        target.clipsToBounds = false
        target.isExclusiveTouch = false
        target.isMultipleTouchEnabled = true
        target.adjustsImageWhenHighlighted = true
    }

    private func addKeyButton(_ title: String, key: Int, size: CGFloat) {
        let control = UIButton(type: .system)
        style(control, titleSize: 11)
        control.setTitle(title, for: .normal)
        control.layer.cornerRadius = size / 2
        let accent: UIColor
        switch title {
        case "FIRE": accent = UIColor(red: 1.00, green: 0.66, blue: 0.76, alpha: 1)       // pastel rose
        case "JUMP": accent = UIColor(red: 0.65, green: 0.91, blue: 0.79, alpha: 1)       // mint
        case "CROUCH": accent = UIColor(red: 0.82, green: 0.72, blue: 0.96, alpha: 1)     // lavender
        case "RELOAD": accent = UIColor(red: 0.55, green: 0.88, blue: 0.91, alpha: 1)     // cyan
        case "NADE": accent = UIColor(red: 0.72, green: 0.78, blue: 1.00, alpha: 1)       // periwinkle
        case "PREV": accent = UIColor(red: 0.64, green: 0.79, blue: 1.00, alpha: 1)       // blue
        default: accent = UIColor(red: 0.70, green: 0.91, blue: 0.84, alpha: 1)
        }
        control.layer.borderColor = accent.cgColor
        control.layer.shadowColor = accent.cgColor
        control.layer.shadowOpacity = 0.42
        control.layer.shadowRadius = 8
        control.tag = key
        control.accessibilityIdentifier = "ac.control.\(title.lowercased())"
        let drag = UIPanGestureRecognizer(target: self, action: #selector(handleControlDrag(_:)))
        drag.delegate = self
        drag.cancelsTouchesInView = true
        control.addGestureRecognizer(drag)
        control.addTarget(self, action: #selector(controlDown(_:)), for: .touchDown)
        for event: UIControl.Event in [.touchUpInside, .touchUpOutside, .touchCancel] {
            control.addTarget(self, action: #selector(controlUp(_:)), for: event)
        }
        control.isHidden = true
        addSubview(control)
        controlButtons.append(control)
    }

    private func addMenuButton(_ title: String, key: Int) {
        let control = UIButton(type: .system)
        style(control, titleSize: 13)
        control.setTitle(title, for: .normal)
        control.layer.cornerRadius = 15
        let accent = title == "OK"
            ? UIColor(red: 0.65, green: 0.92, blue: 0.77, alpha: 1)
            : (title == "BACK" ? UIColor(red: 1.00, green: 0.68, blue: 0.76, alpha: 1)
                               : UIColor(red: 0.66, green: 0.83, blue: 1.00, alpha: 1))
        control.layer.borderColor = accent.cgColor
        control.layer.shadowColor = accent.cgColor
        control.layer.shadowOpacity = 0.32
        control.layer.shadowRadius = 7
        control.tag = key
        control.addTarget(self, action: #selector(controlDown(_:)), for: .touchDown)
        for event: UIControl.Event in [.touchUpInside, .touchUpOutside, .touchCancel] {
            control.addTarget(self, action: #selector(controlUp(_:)), for: event)
        }
        control.isHidden = false
        addSubview(control)
        menuButtons.append(control)
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
        if enabled { setEditingControls(false) }
        joystick.isHidden = enabled || !hudEnabled
        controlButtons.forEach { $0.isHidden = enabled || !hudEnabled }
        menuButtons.forEach { $0.isHidden = !enabled }
        editButton.isHidden = enabled || !hudEnabled
        resetLayoutButton.isHidden = !editingControls || enabled || !hudEnabled
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
        editButton.frame = CGRect(x: bounds.width - 112, y: 12, width: 100, height: 38)
        resetLayoutButton.frame = CGRect(x: bounds.width - 218, y: 12, width: 96, height: 38)

        let scale = hudScale
        let joystickSize: CGFloat = 128 * scale
        joystick.frame = CGRect(x: 22 * scale, y: max(18 * scale, bounds.height - joystickSize - 22 * scale),
                                width: joystickSize, height: joystickSize)
        joystick.layer.cornerRadius = joystickSize / 2
        joystickKnob.frame = CGRect(x: 39 * scale, y: 39 * scale, width: 50 * scale, height: 50 * scale)
        applySavedCenter(to: joystick, key: "joystick")

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
        for control in controlButtons {
            if let key = control.accessibilityIdentifier { applySavedCenter(to: control, key: key) }
        }

        let menuSize: CGFloat = 50
        let menuGap: CGFloat = 7
        let menuTotal = CGFloat(menuButtons.count) * menuSize + CGFloat(max(menuButtons.count - 1, 0)) * menuGap
        let menuStart = max(8, (bounds.width - menuTotal) / 2)
        for (index, control) in menuButtons.enumerated() {
            control.frame = CGRect(x: menuStart + CGFloat(index) * (menuSize + menuGap),
                                   y: max(8, bounds.height - menuSize - 12),
                                   width: menuSize, height: menuSize)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else { return nil }
        let candidates: [UIView] = [button, modeButton, editButton, resetLayoutButton, joystick] + controlButtons.reversed().map { $0 as UIView } + menuButtons.reversed().map { $0 as UIView }
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

    @objc private func toggleEditingControls() {
        setEditingControls(!editingControls)
    }

    private func setEditingControls(_ enabled: Bool) {
        editingControls = enabled
        editButton.setTitle(enabled ? "DONE" : "EDIT HUD", for: .normal)
        resetLayoutButton.isHidden = !enabled || menuMode || !hudEnabled
        joystick.layer.borderColor = (enabled
            ? UIColor(red: 0.65, green: 0.91, blue: 0.80, alpha: 1)
            : UIColor.white.withAlphaComponent(0.55)).cgColor
        joystick.layer.borderWidth = enabled ? 3 : 2
        if enabled { releaseAllDirections() }
    }

    @objc private func resetControlLayout() {
        UserDefaults.standard.removeObject(forKey: layoutDefaultsKey)
        setNeedsLayout()
    }

    private func applySavedCenter(to view: UIView, key: String) {
        guard bounds.width > 0, bounds.height > 0,
              let layouts = UserDefaults.standard.dictionary(forKey: layoutDefaultsKey) as? [String: [Double]],
              let position = layouts[key], position.count >= 2 else { return }
        view.center = CGPoint(x: CGFloat(position[0]) * bounds.width,
                              y: CGFloat(position[1]) * bounds.height)
    }

    private func saveCenter(of view: UIView, key: String) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        var layouts = UserDefaults.standard.dictionary(forKey: layoutDefaultsKey) as? [String: [Double]] ?? [:]
        layouts[key] = [Double(view.center.x / bounds.width), Double(view.center.y / bounds.height)]
        UserDefaults.standard.set(layouts, forKey: layoutDefaultsKey)
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === joystickPan { return !editingControls }
        return editingControls
    }

    @objc private func handleControlDrag(_ gesture: UIPanGestureRecognizer) {
        guard editingControls, let target = gesture.view else { return }
        switch gesture.state {
        case .began:
            dragStartCenter = target.center
        case .changed:
            let translation = gesture.translation(in: self)
            let halfW = target.bounds.width / 2
            let halfH = target.bounds.height / 2
            target.center = CGPoint(
                x: min(max(dragStartCenter.x + translation.x, halfW + 6), bounds.width - halfW - 6),
                y: min(max(dragStartCenter.y + translation.y, halfH + 6), bounds.height - halfH - 6)
            )
        case .ended:
            if target === joystick { saveCenter(of: joystick, key: "joystick") }
            else if let key = target.accessibilityIdentifier { saveCenter(of: target, key: key) }
        default: break
        }
    }

    @objc private func controlDown(_ sender: UIButton) {
        guard !editingControls else { return }
        if sender.tag == -1 { acEngineVirtualMouse(1) }
        else { acEngineVirtualKey(Int32(sender.tag), 1) }
    }

    @objc private func controlUp(_ sender: UIButton) {
        guard !editingControls else { return }
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
        editButton.isHidden = menuMode || !hudEnabled
        if !hudEnabled { setEditingControls(false); releaseAllDirections() }
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
            var previousTimestamp: TimeInterval = 0
            motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
                guard let self, !self.menuMode, !self.editingControls,
                      let sample = data else { return }
                let timestamp = sample.timestamp
                let dt = previousTimestamp > 0 ? min(max(timestamp - previousTimestamp, 0.001), 0.05) : 0
                previousTimestamp = timestamp
                guard dt > 0 else { return }
                let rate = sample.rotationRate
                let orientation = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }.first?.interfaceOrientation ?? .landscapeRight
                var yaw = rate.y
                var pitch = rate.x
                switch orientation {
                case .landscapeRight: yaw = -rate.y; pitch = -rate.x
                case .landscapeLeft: yaw = rate.y; pitch = rate.x
                case .portrait: yaw = rate.z; pitch = rate.x
                case .portraitUpsideDown: yaw = -rate.z; pitch = -rate.x
                default: break
                }
                // Integrate angular velocity over the sample interval. The old
                // code treated rad/s as a per-frame delta, making gyro far too fast.
                let factor = self.gyroSensitivity * 520.0 * dt
                let dx = min(max(yaw * factor, -48), 48)
                let dy = min(max(pitch * factor, -48), 48)
                acEngineGyroMotion(Float(dx), Float(dy))
            }
        } else if !shouldRun && motionManager.isGyroActive {
            motionManager.stopGyroUpdates()
        }
    }

    private func refreshTitle() {
        button.setTitle(keyboardVisible ? "⌨ Hide" : "⌨ Show", for: .normal)
        button.accessibilityLabel = keyboardVisible ? "Hide keyboard" : "Show keyboard"
        modeButton.setTitle(menuMode ? "🎮 Play" : "☰ Menu", for: .normal)
        modeButton.accessibilityLabel = menuMode ? "Show gameplay controls" : "Switch to menu navigation"
        editButton.accessibilityLabel = editingControls ? "Finish moving controls" : "Move touch controls"
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
