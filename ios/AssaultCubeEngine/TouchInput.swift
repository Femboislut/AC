import UIKit

enum TouchInput {
    private static var identifiers: [ObjectIdentifier: Int] = [:]
    private static var nextIdentifier = 1

    static func handleBegan(_ touches: Set<UITouch>, view: UIView) {
        for touch in touches {
            let identifier = identifier(for: touch)
            let point = normalized(touch.location(in: view), in: view)
            EngineBridge.submitTouch(withID: identifier, x: point.x, y: point.y,
                                     deltaX: 0, deltaY: 0, active: true)
        }
    }

    static func handleMoved(_ touches: Set<UITouch>, view: UIView) {
        for touch in touches {
            let identifier = identifier(for: touch)
            let point = normalized(touch.location(in: view), in: view)
            let previous = normalized(touch.previousLocation(in: view), in: view)
            EngineBridge.submitTouch(withID: identifier, x: point.x, y: point.y,
                                     deltaX: point.x - previous.x,
                                     deltaY: point.y - previous.y,
                                     active: true)
        }
    }

    static func handleEnded(_ touches: Set<UITouch>, view: UIView) {
        for touch in touches {
            let objectID = ObjectIdentifier(touch)
            guard let identifier = identifiers.removeValue(forKey: objectID) else { continue }
            let point = normalized(touch.location(in: view), in: view)
            EngineBridge.submitTouch(withID: identifier, x: point.x, y: point.y,
                                     deltaX: 0, deltaY: 0, active: false)
        }
    }

    static func handleCancelled(_ touches: Set<UITouch>, view: UIView) {
        handleEnded(touches, view: view)
    }

    private static func identifier(for touch: UITouch) -> Int {
        let objectID = ObjectIdentifier(touch)
        if let identifier = identifiers[objectID] { return identifier }
        let identifier = nextIdentifier
        nextIdentifier += 1
        identifiers[objectID] = identifier
        return identifier
    }

    private static func normalized(_ point: CGPoint, in view: UIView) -> CGPoint {
        let width = max(view.bounds.width, 1)
        let height = max(view.bounds.height, 1)
        return CGPoint(x: min(max(point.x / width, 0), 1),
                       y: min(max(point.y / height, 0), 1))
    }
}
