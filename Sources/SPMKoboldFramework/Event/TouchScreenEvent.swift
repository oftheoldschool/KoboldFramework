public struct KPanEvent {
    public let state: KPanEventState
    public let position: (x: Float, y: Float)
}

public enum KPanEventState {
    case began
    case panning
    case ended
}

public struct KTapEvent {
    public let state: KTapEventState
    public let type: KTapEventType
    public let position: (x: Float, y: Float)
}

public enum KTapEventType {
    case tap
    case doubleTap
    case longPress
}

public enum KTapEventState {
    case began
    case held
    case ended
}
