import MetalKit.MTKView

class KMetalView: MTKView {
    init(_ sysLink: KSysLink) {
        kdebug("MetalView.init")
        super.init(frame: .zero, device: sysLink.device)
        self.delegate = sysLink
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
