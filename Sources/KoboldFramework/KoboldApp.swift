import SwiftUI

public struct KMacCatalystWindowControls: Sendable {
    public var showsCloseButton: Bool
    public var showsMinimizeButton: Bool
    public var allowsFullScreen: Bool

    public init(
        showsCloseButton: Bool = true,
        showsMinimizeButton: Bool = true,
        allowsFullScreen: Bool = true
    ) {
        self.showsCloseButton = showsCloseButton
        self.showsMinimizeButton = showsMinimizeButton
        self.allowsFullScreen = allowsFullScreen
    }
}

public struct KMacCatalystContentPadding: Sendable {
    public var top: CGFloat
    public var bottom: CGFloat
    public var backgroundColor: (r: Float, g: Float, b: Float)?
    public var guaranteeAspectRatio: Bool

    public init(
        top: CGFloat = 0,
        bottom: CGFloat = 0,
        backgroundColor: (r: Float, g: Float, b: Float)? = nil,
        guaranteeAspectRatio: Bool = false
    ) {
        self.top = top
        self.bottom = bottom
        self.backgroundColor = backgroundColor
        self.guaranteeAspectRatio = guaranteeAspectRatio
    }
}

public struct KWindowSize: Sendable {
    public var width: CGFloat
    public var height: CGFloat

    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }

    var cgSize: CGSize {
        CGSize(width: width, height: height)
    }
}

public struct KMacCatalystConfiguration: Sendable {
    public var preferredWindowSize: KWindowSize?
    public var removesTitleBar: Bool
    public var windowControls: KMacCatalystWindowControls
    public var windowedTopPadding: CGFloat
    public var fullScreenTopPadding: CGFloat
    public var additionalContentPadding: KMacCatalystContentPadding

    public init(
        preferredWindowSize: KWindowSize? = nil,
        removesTitleBar: Bool = true,
        windowControls: KMacCatalystWindowControls = KMacCatalystWindowControls(),
        windowedTopPadding: CGFloat? = nil,
        fullScreenTopPadding: CGFloat = 16,
        additionalContentPadding: KMacCatalystContentPadding = KMacCatalystContentPadding()
    ) {
        self.preferredWindowSize = preferredWindowSize
        self.removesTitleBar = removesTitleBar
        self.windowControls = windowControls

        let resolvedWindowedTopPadding: CGFloat
        if let windowedTopPadding {
            resolvedWindowedTopPadding = windowedTopPadding
        } else {
            let showsTrafficLightArea =
                windowControls.showsCloseButton ||
                windowControls.showsMinimizeButton ||
                windowControls.allowsFullScreen
            resolvedWindowedTopPadding = showsTrafficLightArea ? 44 : 16
        }

        self.windowedTopPadding = resolvedWindowedTopPadding
        self.fullScreenTopPadding = fullScreenTopPadding
        self.additionalContentPadding = additionalContentPadding
    }
}

open class KoboldApp: NSObject {
    @UIApplicationDelegateAdaptor
    public var sysLink: KSysLink
    private(set) public var frameHandler: KFrameHandler?

    open var appName: String { "Kobold Framework Demo" }
    open var showVersion: Bool { false }
    open var showFPS: Bool { false }
    open var showAppMemory: Bool { false }
    open var showGPUMemory: Bool { false }
    open var showScreenshotButton: Bool { false }

    // settings config
    open var showSettings: Bool { false }
    open var showSettingsButton: Bool { true }
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
    open var macCatalystConfiguration: KMacCatalystConfiguration { KMacCatalystConfiguration() }

    // loading screen config
    open var forceLoadingTimeSeconds: TimeInterval { 3 }
    open var loadingScreenFadeTimeSeconds: TimeInterval { 1 }
    open var foregroundColor: (r: Float, g: Float, b: Float) { (r: 0.5, g: 1.0, b: 0.5) }
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
    open var mousePointerMode: KMousePointerMode { .passthrough }

    public override required init() {
        super.init()
#if targetEnvironment(macCatalyst)
        SceneDelegate.configuration = macCatalystConfiguration
#endif
        KLayoutState.shared.update(
            showFPSToggle: showFPS,
            showAppMemoryToggle: showAppMemory,
            showGPUMemoryToggle: showGPUMemory,
            showVersionToggle: showVersion,
            showScreenshotButton: showScreenshotButton,
            showSettingsButton: showSettingsButton,
            macCatalystWindowedTopPadding: macCatalystConfiguration.windowedTopPadding,
            macCatalystFullScreenTopPadding: macCatalystConfiguration.fullScreenTopPadding
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
        self.sysLink.inputSystem.setInputMode(.none)
        self.sysLink.inputSystem.autoSwitchToPhysicalOnConnect = autoSwitchToPhysicalOnConnect
        self.sysLink.inputSystem.autoSwitchToVirtualOnDisconnect = autoSwitchToVirtualOnDisconnect
        self.sysLink.inputSystem.mouseInput.setPointerMode(mousePointerMode)
        self.sysLink.inputSystem.controllerInput.virtualControllerFadeTime = loadingScreenFadeTimeSeconds
        self.frameHandler = createFrameHandler(sysLink: sysLink)

        sysLink.registerFrameHandler(self.frameHandler!)
    }

    open func postSetup() {
    }

    open func createFrameHandler(sysLink: KSysLink) -> KFrameHandler {
        return ExampleBasicFrameHandler(sysLink: sysLink)
    }

    open func getLoadingView() -> (any View)? {
        return BasicLoadingView(
            title: appName,
            foregroundColor: foregroundColor,
            gradientColors: loadingScreenColors)
    }

    open func getSettingsView() -> (any View)? {
        return nil
    }

    @ViewBuilder
    private var rootView: some View {
        KContentView(
            sysLink: sysLink,
            appName: appName,
            showVersion: showVersion,
            showFPS: showFPS,
            showScreenshotButton: showScreenshotButton,
            showSettings: showSettings,
            showSettingsButton: showSettingsButton,
            settingsTitle: settingsTitle,
            showSettingsTitle: showSettingsTitle,
            settingsDimissbuttonTitle: settingsDimissButtonTitle,
            showSettingsDismissButton: showSettingsDismissButton,
            settingsStyle: settingsStyle,
            settingsDeviceStyleOverrides: settingsDeviceStyleOverrides,
            loadingView: getLoadingView(),
            settingsView: getSettingsView(),
            preventScreenSleep: preventScreenSleep,
            loadingScreenFadeTimeSeconds: loadingScreenFadeTimeSeconds,
            macCatalystGuaranteedAspectRatio: {
                guard macCatalystConfiguration.additionalContentPadding.guaranteeAspectRatio,
                      let preferredWindowSize = macCatalystConfiguration.preferredWindowSize
                else { return nil }
                return preferredWindowSize.width / max(preferredWindowSize.height, 1)
            }(),
            macCatalystAdditionalContentPadding: macCatalystConfiguration.additionalContentPadding
        )
        .defaultFont(font: defaultFont)
        .overrideColorScheme(colorScheme: colorScheme)
    }

    @SceneBuilder
    open var body: some Scene {
        #if targetEnvironment(macCatalyst)
        WindowGroup { [self] in
            rootView
        }
        #else
        WindowGroup { [self] in
            rootView
        }
        #endif
    }
}
