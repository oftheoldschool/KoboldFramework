class KTapState {
    var state: KTapAction

    init() {
        self.state = KTapAction(
            state: .none,
            type: .tap,
            position: (x: .zero, y: .zero),
            startPosition: (x: .zero, y: .zero),
            relativeDiff: (x: .zero, y: .zero),
            absoluteDiff: (x: .zero, y: .zero))
    }

    func progressExistingStates() {
        state = state.nextState()
    }

    public func processInputs(events: [KEvent]) {
        progressExistingStates()

        events.forEach { event in
            if case let .input(inputEvent) = event {
                switch inputEvent {
                case .tap(let tapEvent):
                    switch tapEvent.state {
                    case .began:
                        self.state = KTapAction(
                            state: .began,
                            type: KTapActionType.fromTapEventType(tapEvent.type),
                            position: tapEvent.position,
                            startPosition: tapEvent.position,
                            relativeDiff: state.relativeDiff,
                            absoluteDiff: state.absoluteDiff)
                    case .ended:
                        self.state = KTapAction(
                            state: .ended,
                            type: KTapActionType.fromTapEventType(tapEvent.type),
                            position: tapEvent.position,
                            startPosition: state.startPosition,
                            relativeDiff: state.relativeDiff,
                            absoluteDiff: state.absoluteDiff)
                    default:
                        break
                    }
                default:
                    break
                }
            }
        }
    }
}

enum KTapActionType {
    case tap
    case doubleTap
    case longPress

    static func fromTapEventType(_ type: KTapEventType) -> Self {
        return switch type {
        case .tap: .tap
        case .doubleTap: .doubleTap
        case .longPress: .longPress
        }
    }
}

enum KTapActionState {
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
}


struct KTapAction {
    let state: KPanActionState
    let type: KTapActionType
    let position: (x: Float, y: Float)
    let startPosition: (x: Float, y: Float)
    let relativeDiff: (x: Float, y: Float)
    let absoluteDiff: (x: Float, y: Float)

    func nextState() -> Self {
        switch state {
        case .ended:
            return Self(
                state: state.nextState(),
                type: type,
                position: (x: .zero, y: .zero),
                startPosition: (x: .zero, y: .zero),
                relativeDiff: (x: .zero, y: .zero),
                absoluteDiff: (x: .zero, y: .zero))
        default:
            return Self(
                state: state.nextState(),
                type: type,
                position: position,
                startPosition: startPosition,
                relativeDiff: relativeDiff,
                absoluteDiff: absoluteDiff)
        }
    }
}
