import Foundation

public struct KFrameData {
    public let elapsedTime: Float
    public let deltaTime: Float
    public let fps: Float
    public let frameCount: UInt64
    public let frameTimeMs: Float
}

public protocol KFrameHandler: NSObjectProtocol {
    func handleFrame(frameData: KFrameData)
    func handleResize(width: Int, height: Int)
    func handleFocusChange(active: Bool)
}
