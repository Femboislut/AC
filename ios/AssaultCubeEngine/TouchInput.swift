// ios/AssaultCubeEngine/TouchInput.swift
import Foundation
import UIKit

final class TouchInputController {
    private var activePoints: [Int: CGPoint] = [:]

    func beginPoint(_ point: CGPoint, touchID: Int) {
        activePoints[touchID] = point
    }

    func movePoint(_ point: CGPoint, touchID: Int) {
        activePoints[touchID] = point
    }

    func endPoint(_ point: CGPoint, touchID: Int) {
        activePoints.removeValue(forKey: touchID)
    }
}
