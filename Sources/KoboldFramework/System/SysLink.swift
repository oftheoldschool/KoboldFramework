import MetalKit

public class KSysLink: NSObject, ObservableObject {
    // MARK: - Metal Resources
    public let device: MTLDevice
    public var view: MTKView?

    // MARK: - System Resources
    public let fileSystem: KFileSystem

    @Published
    public var inputSystem: KInputSystem

    // MARK: - App State
    var startTime: Double = 0
    var lastUpdate: Double = 0
    var applicationFinishedLaunching: Bool = false

    // MARK: - FPS Tracking
    private var fpsFrameCount: UInt64 = 0
    private let fpsUpdateInterval: Double = 0.25
    var fpsUpdateTime: Double = 0
    public var frameCount: UInt64 = 0

    public var currentFPS: Float = 0
    public var currentFrameTimeMs: Float = 0

    public var bounds: (width: Int, height: Int)
    public var clearColor: (r: Float, g: Float, b: Float)
    public var colorPixelFormat: MTLPixelFormat
    public var depthStencilPixelFormat: MTLPixelFormat

    var eventQueue: KQueue<KEvent>

    // MARK: - Per Frame Handler
    @Published
    open var frameHandler: KFrameHandler?

    @Published
    public var frameHandlerReady: Bool = false

    // MARK: - Init
    override init() {
        let eventQueue = KQueue<KEvent>(maxSize: 2048)
        self.fileSystem = KFileSystem()
        self.inputSystem = KInputSystem(eventQueue: eventQueue)
        self.device = MTLCreateSystemDefaultDevice()!
        self.eventQueue = eventQueue
        self.bounds = (width: 0, height: 0)
        self.clearColor = (r: 0, g: 0, b: 0)
        self.colorPixelFormat = .bgra8Unorm
        self.depthStencilPixelFormat = .depth32Float

        super.init()
    }

    public func getVersionString() -> String {
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "v\(appVersion) (\(buildNumber))"
        }
        return "(unknown build)"
    }

    public func registerFrameHandler(_ frameHandler: KFrameHandler) {
        self.frameHandler = frameHandler
        eventQueue.enqueue(
            item: .resize(
                KEventResize(
                    width: bounds.width,
                    height: bounds.height)))
    }

    public func getMtkView() -> MTKView? {
        return self.view
    }

    public func elapsedTime() -> Float {
        return Float(CACurrentMediaTime() - startTime)
    }

    public func resetElapsedTime() {
        self.startTime = 0
        self.lastUpdate = 0
        self.frameCount = 0
        self.fpsUpdateTime = 0
        self.fpsFrameCount = 0
        self.currentFPS = 0
        self.currentFrameTimeMs = 0  // Reset frame time
    }

    // MARK: - FPS Calculation
    func updateFPS(currentTime: Double) {
        frameCount += 1
        fpsFrameCount += 1

        if currentTime - fpsUpdateTime >= fpsUpdateInterval {
            let timeElapsed = currentTime - fpsUpdateTime
            if timeElapsed > 0 {
                currentFPS = Float(fpsFrameCount) / Float(timeElapsed)
            }
            fpsUpdateTime = currentTime
            fpsFrameCount = 0
        }
    }

    // MARK: - Frame Time Update
    func updateFrameTime(_ frameTimeMs: Float) {
        // Smooth the frame time using exponential moving average
        let alpha: Float = 0.1
        currentFrameTimeMs = alpha * frameTimeMs + (1 - alpha) * currentFrameTimeMs
    }

    public func getCurrentFPS() -> Float {
        return currentFPS
    }

    public func getFrameCount() -> UInt64 {
        return frameCount
    }
}
