import SwiftUI

open class KoboldApp: NSObject {
    @UIApplicationDelegateAdaptor
    public var sysLink: KSysLink
    private(set) public var frameHandler: KFrameHandler?

    open var appName: String { "Kobold" }
    open var showVersion: Bool { true }
    open var showSettings: Bool { false }
    open var forceLoadingTime: Int { 3 }
    open var clearColor: (r: Float, g: Float, b: Float) { (r: 0, g: 0, b: 0) }
    open var loadingScreenColors: [(r: Float, g: Float, b: Float)] = [
        (r: 0.5, g: 0.667, b: 1),
        (r: 0.75, g: 0.334, b: 1),
    ]

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
        }
    }

    open func setup() {
        sysLink.clearColor = clearColor

        let handler = createFrameHandler(sysLink: sysLink)
        frameHandler = handler
        sysLink.registerFrameHandler(handler)
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

    public var windowGroup: WindowGroup<KContentView> {
        WindowGroup { [self] in
            KContentView(
                sysLink: sysLink,
                appName: appName,
                showVersion: showVersion,
                showSettings: showSettings,
                loadingView: getLoadingView(),
                settingsView: getSettingsView())
        }
    }

    public var body: some Scene {
        windowGroup
    }
}
