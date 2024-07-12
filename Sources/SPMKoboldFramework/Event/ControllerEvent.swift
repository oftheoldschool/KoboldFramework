import Foundation
import UIKit

public enum KControllerEvent {
    case screenTap(KControllerEventScreenTap)
    case button(KControllerEventButton)
    case stick(KControllerEventStick)
}

public struct KControllerEventButton {
    public let button: KControllerEventButtonType
    public let state: KControllerEventButtonState
}

public struct KControllerEventScreenTap {
    public let state: KControllerEventTapState
    public let position: (x: Float, y: Float)
}

public enum KControllerEventButtonType {
    case buttonA
    case buttonB
    case buttonX
    case buttonY
    case buttonStart
}

public enum KControllerEventButtonState {
    case pressed
    case released
}

public enum KControllerEventTapState {
    case pressed
    case released
}

public enum KControllerEventStickState {
    case began
    case changed
    case ended
}

public enum KControllerEventStickType {
    case stickLeft
    case stickRight
}

public struct KControllerEventStick {
    public let stick: KControllerEventStickType
    public let state: KControllerEventStickState
    public let offset: (x: Float, y: Float)
}
