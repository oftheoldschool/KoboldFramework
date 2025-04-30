import MetalKit
import KoboldLogging

extension KSysLink: MTKViewDelegate {
    // MARK: - Post Init
    public func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize
    ) {
        kdebug("\(Self.description()).\(#function)")
        kdebug("KSysLink.mtkView self: \(self), view: \(view)")

        view.clearColor = MTLClearColor(
            red: Double(clearColor.r),
            green: Double(clearColor.g),
            blue: Double(clearColor.b),
            alpha: 1)
        view.colorPixelFormat = colorPixelFormat
        view.depthStencilPixelFormat = depthStencilPixelFormat

        self.view = view
        self.bounds = (width: Int(size.width), height: Int(size.height))
        self.eventQueue.enqueue(
            item: .resize(
                KEventResize(
                    width: bounds.width,
                    height: bounds.height)))
    }

    // MARK: - Draw frame
    public func draw(in _: MTKView) {
        if !applicationFinishedLaunching {
            return
        }

        var newTime = CACurrentMediaTime()
        if startTime == 0 {
            startTime = newTime
            newTime = 0
        } else {
            newTime = newTime - startTime
        }
        let deltaTime = newTime - lastUpdate
        lastUpdate = newTime

        let frameData = KFrameData(
            elapsedTime: Float(newTime),
            deltaTime: Float(deltaTime)
        )

        let events = eventQueue.dequeueAll()

        for event in events {
            if case let .resize(r) = event {
                frameHandler?.handleResize(
                    width: Int(r.width),
                    height: Int(r.height))
            } else if case let .focus(focusEvent) = event {
                frameHandler?.handleFocusChange(
                    active: focusEvent.state == .active)
            }
        }

        inputSystem.processInputs(events: events)
        switch inputSystem.inputMode {
        case .controller:
            inputSystem.controllerState.processInputs(events: events)
        case .touchscreen:
            inputSystem.touchScreenState.processInputs(events: events)
        case .hybrid:
            inputSystem.controllerState.processInputs(events: events)
            inputSystem.touchScreenState.processInputs(events: events)
        default:
            break
        }

        if let handler = self.frameHandler {
            handler.handleFrame(frameData: frameData)
        }
    }
}
