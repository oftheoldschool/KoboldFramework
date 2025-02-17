import SwiftUI

open class KoboldApp: NSObject {
    @UIApplicationDelegateAdaptor
    public var sysLink: KSysLink
    private(set) public var frameHandler: KFrameHandler?

    open var appName: String { "Kobold Framework Demo" }
    open var showVersion: Bool { true }
    open var showSettings: Bool { false }
    open var forceLoadingTime: Int { 3 }
    open var colorPixelFormat: MTLPixelFormat { .bgra8Unorm }
    open var depthStencilPixelFormat: MTLPixelFormat { .depth32Float }
    open var clearColor: (r: Float, g: Float, b: Float) { (r: 0, g: 0, b: 0) }
    open var loadingScreenColors: [(r: Float, g: Float, b: Float)] {
        [
            (r: 0.5, g: 0.667, b: 1),
            (r: 0.75, g: 0.334, b: 1),
        ]
    }
    open var defaultFont: Font? { nil }

    public override required init() {
        super.init()
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            setup()
            if forceLoadingTime > 0 {
                sleep(UInt32(forceLoadingTime))
            }
            DispatchQueue.main.async { [self] in
                self.sysLink.frameHandlerReady = true
            }
            postSetup()
        }
    }

    open func setup() {
        self.sysLink.clearColor = clearColor
        self.sysLink.colorPixelFormat = colorPixelFormat
        self.sysLink.depthStencilPixelFormat = depthStencilPixelFormat
        self.frameHandler = createFrameHandler(sysLink: sysLink)

        DispatchQueue.main.async { [self] in
            sysLink.registerFrameHandler(self.frameHandler!)
        }
    }

    open func postSetup() {
    }

    open func createFrameHandler(sysLink: KSysLink) -> KFrameHandler {
        return ExampleBasicFrameHandler(sysLink: sysLink)
    }

    open func getLoadingView() -> (any View)? {
        return BasicLoadingView(
            title: appName,
            gradientColors: loadingScreenColors)
    }

    open func getSettingsView() -> (any View)? {
        return nil
    }

    open var body: some Scene {
        WindowGroup { [self] in
            KContentView(
                sysLink: sysLink,
                appName: appName,
                showVersion: showVersion,
                showSettings: showSettings,
                loadingView: getLoadingView(),
                settingsView: getSettingsView()
            )
            .defaultFont(font: defaultFont)
        }
    }
}
