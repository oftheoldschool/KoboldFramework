public struct KFocusEvent {
    public enum KFocusState {
        case active
        case inactive
    }

    public let state: KFocusState
}

public struct KEventResize {
    public let width: Int
    public let height: Int
}
