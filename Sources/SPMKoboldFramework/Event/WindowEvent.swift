struct KFocusEvent {
    enum KFocusState {
        case active
        case inactive
    }
    
    let state: KFocusState
}

struct KEventResize {
    let width: Int
    let height: Int
}
