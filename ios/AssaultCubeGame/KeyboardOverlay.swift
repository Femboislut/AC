import UIKit

@_silgen_name("ac_ios_toggle_keyboard")
private func acEngineToggleKeyboard()

private final class ACKeyboardOverlayView: UIView {
    private let button = UIButton(type: .system)
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
        refreshTitle()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }

    func configure(x: CGFloat, y: CGFloat, size: CGFloat, visible: Bool) {
        xPercent = min(max(x, 0), 100)
        yPercent = min(max(y, 0), 100)
        buttonSize = min(max(size, 32), 80)
        keyboardVisible = visible
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
        button.frame = CGRect(
            x: margin + availableWidth * xPercent / 100,
            y: margin + availableHeight * yPercent / 100,
            width: width,
            height: height
        )
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else { return nil }
        let local = button.convert(point, from: self)
        return button.bounds.contains(local) ? button.hitTest(local, with: event) : nil
    }

    @objc private func toggleKeyboard() {
        acEngineToggleKeyboard()
    }

    func refreshTitle() {
        button.setTitle(keyboardVisible ? "⌨ Hide" : "⌨ Show", for: .normal)
        button.accessibilityLabel = keyboardVisible ? "Hide keyboard" : "Show keyboard"
    }
}

private enum ACKeyboardOverlay {
    static var overlay: ACKeyboardOverlayView?

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
            overlay?.configure(x: x, y: y, size: size, visible: visible)
            root.bringSubviewToFront(overlay!)
        }
    }
}

@_cdecl("ac_ios_keyboard_overlay_update")
public func acIOSKeyboardOverlayUpdate(_ enabled: Int32, _ inputActive: Int32,
                                      _ keyboardVisible: Int32, _ x: Float, _ y: Float,
                                      _ size: Float) {
    ACKeyboardOverlay.update(enabled: enabled != 0, inputActive: inputActive != 0,
                              visible: keyboardVisible != 0, x: CGFloat(x), y: CGFloat(y),
                              size: CGFloat(size))
}
