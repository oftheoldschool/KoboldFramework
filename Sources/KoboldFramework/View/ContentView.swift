import SwiftUI

public struct KContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var layoutState = KLayoutState.shared
    @StateObject private var screenshotManager = KScreenshotManager()

    @ObservedObject
    var sysLink: KSysLink

    let appName: String
    let showVersion: Bool
    let showFPS: Bool
    let showScreenshotButton: Bool
    let showSettings: Bool
    let settingsTitle: String
    let showSettingsTitle: Bool
    let settingsDismissButtonTitle: String
    let showSettingsDismissButton: Bool
    let settingsView: (any View)?
    let settingsStyle: KModalStyle
    let settingsDeviceStyleOverrides: [KDeviceType: KModalStyle]
    let loadingView: (any View)?
    let preventScreenSleep: Bool
    let loadingScreenFadeTimeSeconds: TimeInterval

    public init(
        sysLink: KSysLink,
        appName: String,
        showVersion: Bool = true,
        showFPS: Bool = false,
        showScreenshotButton: Bool = false,
        showSettings: Bool = false,
        settingsTitle: String,
        showSettingsTitle: Bool,
        settingsDimissbuttonTitle: String,
        showSettingsDismissButton: Bool,
        settingsStyle: KModalStyle,
        settingsDeviceStyleOverrides: [KDeviceType: KModalStyle],
        loadingView: (any View)? = nil,
        settingsView: (any View)? = nil,
        preventScreenSleep: Bool = false,
        loadingScreenFadeTimeSeconds: TimeInterval
    ) {
        self.appName = appName
        self.sysLink = sysLink
        self.showVersion = showVersion
        self.showFPS = showFPS
        self.showScreenshotButton = showScreenshotButton
        self.showSettings = showSettings
        self.settingsTitle = settingsTitle
        self.showSettingsTitle = showSettingsTitle
        self.settingsDismissButtonTitle = settingsDimissbuttonTitle
        self.showSettingsDismissButton = showSettingsDismissButton
        self.settingsView = settingsView
        self.settingsStyle = settingsStyle
        self.settingsDeviceStyleOverrides = settingsDeviceStyleOverrides
        self.loadingView = loadingView
        self.preventScreenSleep = preventScreenSleep
        self.loadingScreenFadeTimeSeconds = loadingScreenFadeTimeSeconds
    }

    public var body: some View {
        appView.edgesIgnoringSafeArea(.all)
            .statusBar(hidden: true)
            .navigationBarHidden(true)
            .environmentObject(screenshotManager)
            .onAppear {
                layoutState.updateTopPadding()
                screenshotManager.configure(sysLink: sysLink)
            }
            .onChange(of: scenePhase) { (_, newPhase) in
                switch newPhase {
                case.active:
                    sysLink.eventQueue.enqueue(item: .focus(KFocusEvent(state: .active)))
                    if preventScreenSleep {
                        UIApplication.shared.isIdleTimerDisabled = true
                    }
                    layoutState.updateTopPadding()
                default:
                    sysLink.eventQueue.enqueue(item: .focus(KFocusEvent(state: .inactive)))
                    if preventScreenSleep {
                        UIApplication.shared.isIdleTimerDisabled = false
                    }
                }
            }
    }

    @ViewBuilder
    var appView: some View {
        ZStack {
            if let loading = loadingView {
                VStack {
                    if !sysLink.frameHandlerReady {
                        AnyView(loading)
                    }
                }
                .zIndex(30)
                .animation(
                    .easeOut(duration: loadingScreenFadeTimeSeconds),
                    value: !sysLink.frameHandlerReady)
                .allowsHitTesting(false)
            }

            VStack {
                HStack(alignment: .top) {
                    if showSettings, let sv = settingsView {
                        KModalView(
                            title: settingsTitle,
                            showTitle: showSettingsTitle,
                            dismissButtonTitle: settingsDismissButtonTitle,
                            showDismissButton: showSettingsDismissButton,
                            viewDefinition: sv,
                            style: settingsStyle,
                            deviceStyleOverrides: settingsDeviceStyleOverrides)
                    }
                    Spacer()
                    VStack {
                        if showFPS && layoutState.showFPSToggle && sysLink.frameHandlerReady {
                            FPSDisplayView(sysLink: sysLink)
                                .padding(.trailing)
                                .padding(.top, layoutState.topPadding)
                        }
                        if showScreenshotButton && layoutState.showScreenshotButtonToggle && sysLink.frameHandlerReady {
                            KScreenshotButton(style: .compact)
                                .padding(.trailing)
                                .padding(.top, !(showFPS && layoutState.showFPSToggle) ? layoutState.topPadding : 8)
                        }
                    }
                }
                Spacer()
                if showVersion && layoutState.showVersionToggle {
                    HStack {
                        Text("\(appName) \(sysLink.getVersionString())")
                            .font(Font.system(size: 12).bold().monospaced())
                            .shadow(
                                color: Color(red: 0, green: 0, blue: 0, opacity: 0.8),
                                radius: 2,
                                x: 2,
                                y: 2)
                            .foregroundColor(Color(red:0.5, green: 1.0, blue: 0.5))
                            .padding()
                            .allowsHitTesting(false)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
            }
            .zIndex(20)

            KWrappedUIView {
                let metalView = KMetalView(
                    sysLink: sysLink,
                    showScreenshotButton: showScreenshotButton)
                metalView.translatesAutoresizingMaskIntoConstraints = false
                metalView.autoResizeDrawable = true
                
                return metalView
            }
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity)
            .zIndex(10)
        }
    }
}

// MARK: - FPS Display View
struct FPSDisplayView: View {
    let sysLink: KSysLink
    
    @State private var displayFPS: Float = 0
    @State private var displayFrameTimeMs: Float = 0
    @State private var fpsTimer: Timer?
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(String(format: "%.1f", floor(displayFPS * 10) / 10)) fps")
                .font(Font.system(size: 12).bold().monospaced())
                .shadow(
                    color: Color(red: 0, green: 0, blue: 0, opacity: 0.8),
                    radius: 2,
                    x: 2,
                    y: 2)
                .foregroundColor(Color(red:0.5, green: 1.0, blue: 0.5))

            Text("\(String(format: "%.2f", displayFrameTimeMs))ms")
                .font(Font.system(size: 12).monospaced())
                .shadow(
                    color: Color(red: 0, green: 0, blue: 0, opacity: 0.8),
                    radius: 2,
                    x: 2,
                    y: 2)
                .foregroundColor(Color(red:0.5, green: 1.0, blue: 0.5))
        }
        .allowsHitTesting(false)
        .onAppear {
            startFPSTimer()
        }
        .onDisappear {
            stopFPSTimer()
        }
    }
    
    private func startFPSTimer() {
        fpsTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            displayFPS = sysLink.currentFPS
            displayFrameTimeMs = sysLink.currentFrameTimeMs
        }
    }
    
    private func stopFPSTimer() {
        fpsTimer?.invalidate()
        fpsTimer = nil
    }
}
