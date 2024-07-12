import Foundation

public struct KFrameData {
    public let elapsedTime: Float
    public let deltaTime: Float
}

public protocol KFrameHandler: NSObjectProtocol {
    func handleFrame(frameData: KFrameData)
    func handleResize(width: Int, height: Int)
}
