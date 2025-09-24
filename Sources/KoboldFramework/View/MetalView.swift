import MetalKit.MTKView
import KoboldLogging

class KMetalView: MTKView {
    init(
        sysLink: KSysLink,
        showScreenshotButton: Bool
    ) {
        kdebug("MetalView.init")
        super.init(frame: .zero, device: sysLink.device)
        self.delegate = sysLink

        if showScreenshotButton {
            self.framebufferOnly = false
        }
        kdebug("MetalView: framebufferOnly set to false for screenshot support")
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
