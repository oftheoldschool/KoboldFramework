class KTouchScreenState {
    let panState: KPanState
    let tapState: KTapState
    
    init() {
        panState = KPanState()
        tapState = KTapState()
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
