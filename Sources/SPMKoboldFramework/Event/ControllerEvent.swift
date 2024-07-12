import Foundation
import UIKit

enum KControllerEvent {
    case screenTap(KControllerEventScreenTap)
    case button(KControllerEventButton)
    case stick(KControllerEventStick)
}

struct KControllerEventButton {
    let button: KControllerEventButtonType
    let state: KControllerEventButtonState
}

struct KControllerEventScreenTap {
    let state: KControllerEventTapState
    let position: (x: Float, y: Float)
}

enum KControllerEventButtonType {
    case buttonA
    case buttonB
    case buttonX
    case buttonY
    case buttonStart
}

enum KControllerEventButtonState {
    case pressed
    case released
}

enum KControllerEventTapState {
    case pressed
    case released
}

enum KControllerEventStickState {
    case began
    case changed
    case ended
}

enum KControllerEventStickType {
    case stickLeft
    case stickRight
}

struct KControllerEventStick {
    let stick: KControllerEventStickType
    let state: KControllerEventStickState
    let offset: (x: Float, y: Float)
}
