import SwiftUI

public struct KContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var layoutState = KLayoutState.shared
    @StateObject private var screenshotManager = KScreenshotManager()

    @ObservedObject
    var sysLink: KSysLink

    let appName: String
    let showSettings: Bool
    let settingsTitle: String
    let showSettingsTitle: Bool
    let showSettingsButton: Bool
    let settingsDismissButtonTitle: String
    let showSettingsDismissButton: Bool
    let settingsView: (any View)?
    let settingsStyle: KModalStyle
    let settingsDeviceStyleOverrides: [KDeviceType: KModalStyle]
    let loadingView: (any View)?
    let preventScreenSleep: Bool
    let loadingScreenFadeTimeSeconds: TimeInterval
    let macCatalystAdditionalContentPadding: KMacCatalystContentPadding

    public init(
        sysLink: KSysLink,
        appName: String,
        showVersion: Bool = true,
        showFPS: Bool = false,
        showScreenshotButton: Bool = false,
        showSettings: Bool = false,
        showSettingsButton: Bool = true,
        settingsTitle: String,
        showSettingsTitle: Bool,
        settingsDimissbuttonTitle: String,
        showSettingsDismissButton: Bool,
        settingsStyle: KModalStyle,
        settingsDeviceStyleOverrides: [KDeviceType: KModalStyle],
        loadingView: (any View)? = nil,
        settingsView: (any View)? = nil,
        preventScreenSleep: Bool = false,
        loadingScreenFadeTimeSeconds: TimeInterval,
        macCatalystAdditionalContentPadding: KMacCatalystContentPadding = KMacCatalystContentPadding()
    ) {
        self.appName = appName
        self.sysLink = sysLink
        self.showSettings = showSettings
        self.showSettingsButton = showSettingsButton
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
        self.macCatalystAdditionalContentPadding = macCatalystAdditionalContentPadding
    }

    public var body: some View {
        ZStack {
            backgroundColor
            appView
                .padding(.top, macCatalystAdditionalContentPadding.top)
                .padding(.bottom, macCatalystAdditionalContentPadding.bottom)
        }
        .edgesIgnoringSafeArea(.all)
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

    private var backgroundColor: Color {
        let resolvedColor = macCatalystAdditionalContentPadding.backgroundColor
            ?? sysLink.clearColor
        return Color(
            red: Double(resolvedColor.r),
            green: Double(resolvedColor.g),
            blue: Double(resolvedColor.b)
        )
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
                            showButton: showSettingsButton,
                            dismissButtonTitle: settingsDismissButtonTitle,
                            showDismissButton: showSettingsDismissButton,
                            viewDefinition: sv,
                            style: settingsStyle,
                            deviceStyleOverrides: settingsDeviceStyleOverrides)
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        if layoutState.showFPS && sysLink.frameHandlerReady {
                            HStack {
                                Spacer()
                                FPSDisplayView(sysLink: sysLink)
                                    .padding(.trailing)
                                    .padding(.top, layoutState.topPadding)
                            }
                        }
                        if (layoutState.showAppMemory || layoutState.showGPUMemory) && sysLink.frameHandlerReady {
                            HStack {
                                Spacer()
                                MemoryDisplayView(
                                    sysLink: sysLink,
                                    showAppMemory: layoutState.showAppMemory,
                                    showGPUMemory: layoutState.showGPUMemory)
                                    .padding(.trailing)
                                    .padding(.top, !layoutState.showFPS ? layoutState.topPadding : 2)
                            }
                        }
                        if layoutState.showScreenshotButton && sysLink.frameHandlerReady {
                            let anyOverlayAbove = layoutState.showFPS || layoutState.showAppMemory || layoutState.showGPUMemory
                            HStack {
                                Spacer()
                                KScreenshotButton(style: .compact)
                                    .padding(.trailing)
                                    .padding(.top, !anyOverlayAbove ? layoutState.topPadding : 8)
                            }
                        }
                    }
                }
                Spacer()
                if layoutState.showVersion {
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
                let metalView = KMetalView(sysLink: sysLink)
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

// MARK: - Memory Display View
struct MemoryDisplayView: View {
    let sysLink: KSysLink
    let showAppMemory: Bool
    let showGPUMemory: Bool

    @State private var stats: KMemoryStats = KMemoryStats(
        appUsedBytes: 0,
        appAvailableBytes: 0,
        gpuAllocatedBytes: 0,
        gpuBudgetBytes: 0)
    @State private var memoryTimer: Timer?

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if showAppMemory {
                metricLine(label: "app", usedBytes: stats.appUsedBytes)
            }
            if showGPUMemory {
                metricLine(label: "gpu", usedBytes: stats.gpuAllocatedBytes)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            sample()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    @ViewBuilder
    private func metricLine(label: String, usedBytes: UInt64) -> some View {
        Text("\(label) \(format(usedBytes))")
            .font(Font.system(size: 12).monospaced())
            .shadow(
                color: Color(red: 0, green: 0, blue: 0, opacity: 0.8),
                radius: 2,
                x: 2,
                y: 2)
            .foregroundColor(Color(red: 0.5, green: 1.0, blue: 0.5))
    }

    private func format(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024.0 * 1024.0)
        if mb >= 1000 {
            return String(format: "%.1f GB", mb / 1024.0)
        } else if mb >= 100 {
            return String(format: "%.0f MB", mb)
        } else {
            return String(format: "%.1f MB", mb)
        }
    }

    private func sample() {
        stats = KMemoryStats.current(device: sysLink.device)
    }

    private func startTimer() {
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            sample()
        }
    }

    private func stopTimer() {
        memoryTimer?.invalidate()
        memoryTimer = nil
    }
}
