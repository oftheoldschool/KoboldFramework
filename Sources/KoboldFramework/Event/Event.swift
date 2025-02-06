import MetalKit.MTKView

public enum KEvent {
    case resize(KEventResize)
    case input(KInputEvent)
    case focus(KFocusEvent)
}

public enum KInputEvent {
    case controller(KControllerEvent)
    case pan(KPanEvent)
    case tap(KTapEvent)
}
