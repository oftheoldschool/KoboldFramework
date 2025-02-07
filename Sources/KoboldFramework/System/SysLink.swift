import MetalKit
import SwiftUI
@_implementationOnly import KoboldLogging

public enum KInputMode {
    case controller
    case touchscreen
    case none
}

public class KSysLink: NSObject, ObservableObject {
    // MARK: - Metal Resources
    public let device: MTLDevice
    public var view: MTKView?

    // MARK: - System Resources
    public let fileSystem: KFileSystem

    // MARK: - App State
    var startTime: Double = 0
    var lastUpdate: Double = 0
    var applicationFinishedLaunching: Bool = false

    public var bounds: (width: Int, height: Int)
    public var clearColor: (r: Float, g: Float, b: Float)
    public var colorPixelFormat: MTLPixelFormat
    public var depthStencilPixelFormat: MTLPixelFormat

    public var inputMode: KInputMode = .none
    public var inputVisible: Bool = true

    public var touchScreenInput: KTouchScreenInput!
    public var touchScreenState: KTouchScreenState!

    public var controllerInput: KControllerInput!
    public var controllerState: KControllerState!

    var eventQueue: KQueue<KEvent>

    // MARK: - Per Frame Handler
    @Published
    open var frameHandler: KFrameHandler?

    @Published
    public var frameHandlerReady: Bool = false

    // MARK: - Init
    override init() {
        self.fileSystem = KFileSystem()
        self.device = MTLCreateSystemDefaultDevice()!
        self.inputMode = .none
        self.applicationFinishedLaunching = false
        self.eventQueue = KQueue(maxSize: 2048)
        self.bounds = (width: 0, height: 0)
        self.clearColor = (r: 0, g: 0, b: 0)
        self.colorPixelFormat = .bgra8Unorm
        self.depthStencilPixelFormat = .depth32Float

        super.init()

        self.touchScreenInput = KTouchScreenInput(eventQueue: eventQueue)
        self.touchScreenState = KTouchScreenState()

        self.controllerInput = KControllerInput(eventQueue: eventQueue)
        self.controllerState = KControllerState()
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
    }

    public func setInputMode(_ inputMode: KInputMode) {
        self.inputMode = inputMode
        refreshInputMode()
    }

    public func refreshInputMode() {
        if let mainView = view {
            kdebug("Refreshing input mode")
            for v in mainView.subviews {
                v.removeFromSuperview()
            }

            view!.gestureRecognizers?.forEach { recognizer in
                recognizer.removeTarget(self, action: nil)
                recognizer.isEnabled = false
                mainView.removeGestureRecognizer(recognizer)
            }

            switch inputMode {
            case .touchscreen:
                touchScreenInput.registerWithView(view: mainView)
            case .controller:
                controllerInput.registerWithView(
                    view: mainView,
                    visibleControls: inputVisible)
            case .none:
                break
            }
        }
    }
}
