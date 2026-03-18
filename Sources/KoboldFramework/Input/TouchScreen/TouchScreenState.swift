public class KTouchScreenState {
    public let panState: KPanState
    public let tapState: KTapState

    init() {
        panState = KPanState()
        tapState = KTapState()
    }

    public func reset() {
        panState.reset()
        tapState.reset()
    }

    func progressExistingStates() {
        panState.progressExistingStates()
        tapState.progressExistingStates()
    }

    func processInputs(events: [KEvent]) {
        progressExistingStates()

        panState.processInputs(events: events)
        tapState.processInputs(events: events)
    }
}
