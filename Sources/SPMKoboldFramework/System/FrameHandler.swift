import Foundation

public struct KFrameData {
    let elapsedTime: Float
    let deltaTime: Float
}

public protocol KFrameHandler: NSObjectProtocol {
    func handleFrame(frameData: KFrameData)
    func handleResize(width: Int, height: Int)
}
