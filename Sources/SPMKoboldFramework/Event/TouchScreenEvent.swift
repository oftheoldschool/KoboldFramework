struct KPanEvent {
    let state: KPanEventState
    let position: (x: Float, y: Float)
}

enum KPanEventState {
    case began
    case panning
    case ended
}

struct KTapEvent {
    let state: KTapEventState
    let type: KTapEventType
    let position: (x: Float, y: Float)
}

enum KTapEventType {
    case tap
    case doubleTap
    case longPress
}

enum KTapEventState {
    case began
    case held
    case ended
}
