import Foundation
import SwiftUI
import simd

public class KControllerState {
    public var screenButton: KControllerStateTap
    public var buttonA: KControllerStateButtonState
    public var buttonB: KControllerStateButtonState
    public var buttonX: KControllerStateButtonState
    public var buttonY: KControllerStateButtonState
    public var buttonStart: KControllerStateButtonState
    public var leftStick: KControllerStateStick
    public var rightStick: KControllerStateStick

    private func progressExistingStates() {
        screenButton = screenButton.nextState()
        buttonA = buttonA.nextState()
        buttonB = buttonB.nextState()
        buttonX = buttonX.nextState()
        buttonY = buttonY.nextState()
        buttonStart = buttonStart.nextState()
        leftStick = leftStick.nextState()
        rightStick = rightStick.nextState()
    }

    init() {
        screenButton = KControllerStateTap(
            state: .none,
            position: (.zero, .zero))
        buttonA = .none
        buttonB = .none
        buttonX = .none
        buttonY = .none
        buttonStart = .none
        leftStick = KControllerStateStick(state: .none, offset: (x: .zero, y: .zero))
        rightStick = KControllerStateStick(state: .none, offset: (x: .zero, y: .zero))
    }

    func processInputs(events: [KEvent]) {
        progressExistingStates()

        events.forEach { event in
            if case let .input(inputEvent) = event {
                switch inputEvent {
                case .controller(let controllerEvent):
                    switch controllerEvent {
                    case .screenTap(let tapEvent):
                        switch tapEvent.state {
                        case .pressed:
                            self.screenButton = KControllerStateTap(
                                state: .tapped,
                                position: tapEvent.position)
                        default:
                            break
                        }
                    case .button(let buttonEvent):
                        if buttonEvent.button == .buttonA {
                            switch buttonEvent.state {
                            case .pressed:
                                self.buttonA = .began
                            case .released:
                                self.buttonA = .ended
                            }
                        } else if buttonEvent.button == .buttonB {
                            switch buttonEvent.state {
                            case .pressed:
                                self.buttonB = .began
                            case .released:
                                self.buttonB = .ended
                            }
                        } else if buttonEvent.button == .buttonX {
                            switch buttonEvent.state {
                            case .pressed:
                                self.buttonX = .began
                            case .released:
                                self.buttonX = .ended
                            }
                        } else if buttonEvent.button == .buttonY {
                            switch buttonEvent.state {
                            case .pressed:
                                self.buttonY = .began
                            case .released:
                                self.buttonY = .ended
                            }
                        } else if buttonEvent.button == .buttonStart {
                            switch buttonEvent.state {
                            case .pressed:
                                self.buttonStart = .began
                            case .released:
                                self.buttonStart = .ended
                            }
                        }
                    case .stick(let stickEvent):
                        if stickEvent.stick == .stickLeft {
                            switch stickEvent.state {
                            case .began:
                                self.leftStick = KControllerStateStick(
                                    state: .began,
                                    offset: stickEvent.offset)
                            case .changed:
                                self.leftStick = KControllerStateStick(
                                    state: .held,
                                    offset: stickEvent.offset)
                            case .ended:
                                self.leftStick = KControllerStateStick(
                                    state: .ended,
                                    offset: stickEvent.offset)
                            }
                        } else if stickEvent.stick == .stickRight {
                            switch stickEvent.state {
                            case .began:
                                self.rightStick = KControllerStateStick(
                                    state: .began,
                                    offset: stickEvent.offset)
                            case .changed:
                                self.rightStick = KControllerStateStick(
                                    state: .held,
                                    offset: stickEvent.offset)
                            case .ended:
                                self.rightStick = KControllerStateStick(
                                    state: .ended,
                                    offset: stickEvent.offset)
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}

public struct KControllerStateStick {
    public let state: KControllerStateStickState
    public let offset: (x: Float, y: Float)

    func nextState() -> Self {
        switch state {
        case .ended:
            return Self(state: state.nextState(), offset: (x: .zero, y: .zero))
        default:
            return Self(state: state.nextState(), offset: offset)
        }
    }
}

public enum KControllerStateStickState {
    case none
    case began
    case held
    case ended

    func nextState() -> Self {
        switch self {
        case .began:
            return .held
        case .ended:
            return .none
        default:
            return self
        }
    }

    public func isActive() -> Bool {
        return self == .began || self == .held
    }

    public func isInactive() -> Bool {
        return self == .ended || self == .none
    }
}

public struct KControllerStateTap {
    public let state: KControllerStateTapState
    public let position: (x: Float, y: Float)

    func nextState() -> Self {
        switch state {
        case .tapped:
            return Self(state: state.nextState(), position: (x: .zero, y: .zero))
        default:
            return Self(state: state.nextState(), position: position)
        }
    }
}

public enum KControllerStateTapState {
    case none
    case tapped

    func nextState() -> Self {
        switch self {
        case .tapped:
            return .none
        default:
            return self
        }
    }

    public func isActive() -> Bool {
        return self == .tapped
    }

    public func isInactive() -> Bool {
        return self == .none
    }
}

public struct KControllerStateButton {
    public let state: KControllerStateButtonState
    public let position: (x: Float, y: Float)

    func nextState() -> Self {
        switch state {
        case .ended:
            return Self(state: state.nextState(), position: (x: .zero, y: .zero))
        default:
            return Self(state: state.nextState(), position: position)
        }
    }
}

public enum KControllerStateButtonState {
    case none
    case began
    case held
    case ended

    func nextState() -> Self {
        switch self {
        case .began:
            return .held
        case .ended:
            return .none
        default:
            return self
        }
    }

    public func isActive() -> Bool {
        return self == .began || self == .held
    }

    public func isReleased() -> Bool {
        return self == .ended
    }

    public func isInactive() -> Bool {
        return self == .none || self == .ended
    }
}
