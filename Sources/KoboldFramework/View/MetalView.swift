import MetalKit.MTKView
import KoboldLogging
import SwiftUI

class KMetalView: MTKView {
    @ObservedObject private var layoutState = KLayoutState.shared

    init(
        sysLink: KSysLink,
    ) {
        kdebug("MetalView.init")
        super.init(frame: .zero, device: sysLink.device)
        self.delegate = sysLink

        if layoutState.showScreenshotButton {
            self.framebufferOnly = false
        }
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
