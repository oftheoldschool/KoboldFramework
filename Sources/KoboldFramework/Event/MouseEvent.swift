import Foundation
import UIKit
import GameController

public enum KMouseEvent {
    case buttonDown(KMouseEventButton)
    case buttonUp(KMouseEventButton)
    case move(KMouseEventMove)
    case scroll(KMouseEventScroll)
}

public struct KMouseEventButton {
    public let button: KMouseButton
    public let clickCount: Int

    public init(button: KMouseButton, clickCount: Int = 1) {
        self.button = button
        self.clickCount = clickCount
    }
}

public struct KMouseEventMove {
    public let deltaX: Float
    public let deltaY: Float
    public let position: CGPoint?
}

public struct KMouseEventScroll {
    public let deltaX: Float
    public let deltaY: Float
}

public enum KMouseButton {
    case unknown
    case left
    case right
    case middle
    case auxiliary1
    case auxiliary2
    
    static func fromGCMouseInput(_ button: GCControllerButtonInput) -> KMouseButton {
        // GCMouse doesn't provide specific constants for mouse buttons
        // We can identify them by their element names
        let elementName = button.description

        return switch elementName.lowercased() {
        case "button a", "left button", "primary button": .left
        case "button b", "right button", "secondary button": .right
        case "button x", "middle button", "tertiary button": .middle
        case "button y", "auxiliary1", "fourth button": .auxiliary1
        case "button 5", "auxiliary2", "fifth button": .auxiliary2
        default: .unknown
        }
    }
}
