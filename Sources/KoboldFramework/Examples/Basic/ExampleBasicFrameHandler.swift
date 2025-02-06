import Foundation

class ExampleBasicFrameHandler: NSObject, KFrameHandler {
    let sysLink: KSysLink
    let renderer: ExampleBasicRenderer

    init(sysLink: KSysLink) {
        self.sysLink = sysLink
        self.renderer = ExampleBasicRenderer(device: sysLink.device)
    }

    func handleFrame(frameData: KFrameData) {
        renderer.draw(
            mtkView: sysLink.view,
            elapsedTime: frameData.elapsedTime
        )
    }

    func handleResize(width: Int, height: Int) {
        renderer.bounds = (
            width: Float(width),
            height: Float(height))
    }

    func handleFocusChange(active: Bool) {
    }
}
