import MetalKit.MTKView

enum KEvent {
    case resize(KEventResize)
    case input(KInputEvent)
    case focus(KFocusEvent)
}

enum KInputEvent {
    case controller(KControllerEvent)
    case pan(KPanEvent)
    case tap(KTapEvent)
}
