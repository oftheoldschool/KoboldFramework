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
            fpsUpdateTime = 0
            newTime = 0
        } else {
            newTime = newTime - startTime
        }
        let deltaTime = newTime - lastUpdate
        lastUpdate = newTime

        updateFPS(currentTime: newTime)

        let frameData = KFrameData(
            elapsedTime: Float(newTime),
            deltaTime: Float(deltaTime),
            fps: currentFPS,
            frameCount: frameCount
        )

        kinfo(currentFPS)

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

        if inputSystem.inputMode.contains(.controller) {
            inputSystem.controllerState.processInputs(events: events)
        }

        if inputSystem.inputMode.contains(.touchscreen) {
            inputSystem.touchScreenState.processInputs(events: events)
        }

        if inputSystem.inputMode.contains(.keyboard) {
            inputSystem.keyboardState.processInputs(events: events)
        }

        if inputSystem.inputMode.contains(.mouse) {
            inputSystem.mouseState.processInputs(events: events)
        }

        if let handler = self.frameHandler {
            handler.handleFrame(frameData: frameData)
        }
    }
}
