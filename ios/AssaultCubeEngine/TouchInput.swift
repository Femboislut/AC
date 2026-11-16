import Foundation
import UIKit

enum TouchInput {
    static func handleBegan(_ touches: Set<UITouch>, view: UIView) {
        for touch in touches {
            let point = touch.location(in: view)
            _ = point
        }
    }

    static func handleMoved(_ touches: Set<UITouch>, view: UIView) {
        for touch in touches {
            let point = touch.location(in: view)
            let previous = touch.previousLocation(in: view)
            _ = (point, previous)
        }
    }

    static func handleEnded(_ touches: Set<UITouch>, view: UIView) {
        for touch in touches {
            let point = touch.location(in: view)
            _ = point
        }
    }
}
