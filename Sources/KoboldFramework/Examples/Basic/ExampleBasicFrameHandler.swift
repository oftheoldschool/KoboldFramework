import Foundation

class ExampleBasicFrameHandler: NSObject, KFrameHandler {
    let renderer: ExampleBasicRenderer

    init(sysLink: KSysLink) {
        self.renderer = ExampleBasicRenderer(sysLink: sysLink)
    }

    func handleFrame(frameData: KFrameData) {
        renderer.draw(frameData: frameData)
    }

    func handleResize(width: Int, height: Int) {
        renderer.bounds = (
            width: Float(width),
            height: Float(height))
    }

    func handleFocusChange(active: Bool) {
    }
}
