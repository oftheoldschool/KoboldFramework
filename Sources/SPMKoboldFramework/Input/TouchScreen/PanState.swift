class KPanState {
    var action: KPanAction

    init() {
        self.action = KPanAction(
            state: .none,
            position: (x: .zero, y: .zero),
            startPosition: (x: .zero, y: .zero),
            relativeDiff: (x: .zero, y: .zero),
            absoluteDiff: (x: .zero, y: .zero))
    }

    func progressExistingStates() {
        action = action.nextAction()
    }

    public func processInputs(events: [KEvent]) {
        progressExistingStates()

        events.forEach { event in
            if case let .input(inputEvent) = event {
                switch inputEvent {
                case .pan(let panEvent):
                    switch panEvent.state {
                    case .began:
                        self.action = KPanAction(
                            state: .began,
                            position: panEvent.position,
                            startPosition: panEvent.position,
                            relativeDiff: action.relativeDiff,
                            absoluteDiff: action.absoluteDiff)
                    case .panning:
                        let relativeDiff = (
                            x: panEvent.position.x - action.position.x,
                            y: action.position.y - panEvent.position.y)
                        let absoluteDiff = (
                            x: panEvent.position.x - action.startPosition.x,
                            y: action.startPosition.y - panEvent.position.y)

                        self.action = KPanAction(
                            state: .panning,
                            position: panEvent.position,
                            startPosition: action.startPosition,
                            relativeDiff: relativeDiff,
                            absoluteDiff: absoluteDiff)
                    case .ended:
                        self.action = KPanAction(
                            state: .ended,
                            position: panEvent.position,
                            startPosition: action.startPosition,
                            relativeDiff: action.relativeDiff,
                            absoluteDiff: action.absoluteDiff)
                    }
                default:
                    break
                }
            }
        }
    }
}

enum KPanActionState {
    case none
    case began
    case panning
    case ended

    func nextState() -> Self {
        switch self {
        case .began:
            return .panning
        case .ended:
            return .none
        default:
            return self
        }
    }
}

struct KPanAction {
    let state: KPanActionState
    let position: (x: Float, y: Float)
    let startPosition: (x: Float, y: Float)
    let relativeDiff: (x: Float, y: Float)
    let absoluteDiff: (x: Float, y: Float)

    func nextAction() -> Self {
        switch state {
        case .ended:
            return Self(
                state: state.nextState(), 
                position: (x: .zero, y: .zero), 
                startPosition: (x: .zero, y: .zero),
                relativeDiff: (x: .zero, y: .zero),
                absoluteDiff: (x: .zero, y: .zero))
        default:
            return Self(
                state: state.nextState(), 
                position: position, 
                startPosition: startPosition,
                relativeDiff: relativeDiff,
                absoluteDiff: absoluteDiff)
        }
    }
}
