import SwiftUI

open class KoboldApp: NSObject {
    @UIApplicationDelegateAdaptor
    public var sysLink: KSysLink
    private(set) public var frameHandler: KFrameHandler?

    open var appName: String { "Kobold Framework Demo" }
    open var showVersion: Bool { false }
    open var showFPS: Bool { false }
    open var showScreenshotButton: Bool { false }

    // settings config
    open var showSettings: Bool { false }
    open var settingsStyle: KModalStyle { [.medium, .large] }
    open var settingsDeviceStyleOverrides: [KDeviceType: KModalStyle] { [:] }
    open var settingsTitle: String { "Settings" }
    open var showSettingsTitle: Bool { false }
    open var settingsDimissButtonTitle: String { "Done" }
    open var showSettingsDismissButton: Bool { true }

    // metal view config
    open var colorPixelFormat: MTLPixelFormat { .bgra8Unorm }
    open var depthStencilPixelFormat: MTLPixelFormat { .depth32Float }
    open var clearColor: (r: Float, g: Float, b: Float) { (r: 0, g: 0, b: 0) }

    // general ux config
    open var preventScreenSleep: Bool { false }
    open var defaultFont: Font? { nil }
    open var colorScheme: ColorScheme? { nil }

    // loading screen config
    open var forceLoadingTimeSeconds: TimeInterval { 3 }
    open var loadingScreenFadeTimeSeconds: TimeInterval { 1 }
    open var loadingScreenColors: [(r: Float, g: Float, b: Float)] {
        [
            (r: 0.5, g: 0.667, b: 1),
            (r: 0.75, g: 0.334, b: 1),
        ]
    }

    // input config
    open var defaultInputMode: KInputMode { .none }
    open var autoSwitchToPhysicalOnConnect: Bool { true }
    open var autoSwitchToVirtualOnDisconnect: Bool { true }

    public override required init() {
        super.init()
        KLayoutState.shared.update(
            showFPSToggle: showFPS,
            showVersionToggle: showVersion,
            showScreenshotButton: showScreenshotButton
        )

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            setup()
            if forceLoadingTimeSeconds > 0 {
                sleep(UInt32(forceLoadingTimeSeconds))
            }
            DispatchQueue.main.async { [self] in
                self.sysLink.frameHandlerReady = true
            }
            self.sysLink.inputSystem.setInputMode(defaultInputMode)
            postSetup()
        }
    }

    open func setup() {
        self.sysLink.clearColor = clearColor
        self.sysLink.colorPixelFormat = colorPixelFormat
        self.sysLink.depthStencilPixelFormat = depthStencilPixelFormat
        self.sysLink.inputSystem.inputMode = .none
        self.sysLink.inputSystem.autoSwitchToPhysicalOnConnect = autoSwitchToPhysicalOnConnect
        self.sysLink.inputSystem.autoSwitchToVirtualOnDisconnect = autoSwitchToVirtualOnDisconnect
        self.sysLink.inputSystem.controllerInput.virtualControllerFadeTime = loadingScreenFadeTimeSeconds
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
                showFPS: showFPS,
                showScreenshotButton: showScreenshotButton,
                showSettings: showSettings,
                settingsTitle: settingsTitle,
                showSettingsTitle: showSettingsTitle,
                settingsDimissbuttonTitle: settingsDimissButtonTitle,
                showSettingsDismissButton: showSettingsDismissButton,
                settingsStyle: settingsStyle,
                settingsDeviceStyleOverrides: settingsDeviceStyleOverrides,
                loadingView: getLoadingView(),
                settingsView: getSettingsView(),
                preventScreenSleep: preventScreenSleep,
                loadingScreenFadeTimeSeconds: loadingScreenFadeTimeSeconds
            )
            .defaultFont(font: defaultFont)
            .overrideColorScheme(colorScheme: colorScheme)
        }
    }
}
