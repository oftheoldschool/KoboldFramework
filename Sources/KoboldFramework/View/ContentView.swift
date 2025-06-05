import SwiftUI

public struct KContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var layoutState = KLayoutState.shared

    @ObservedObject
    var sysLink: KSysLink

    let appName: String
    let showVersion: Bool
    let showFPS: Bool
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
            .onAppear {
                layoutState.updateTopPadding()
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
                HStack {
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
                    if showFPS && layoutState.showFPSToggle && sysLink.frameHandlerReady {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(String(format: "%.1f", floor(sysLink.currentFPS * 10) / 10)) FPS")
                                .font(Font.system(size: 12).bold().monospaced())
                                .shadow(
                                    color: Color(red: 0, green: 0, blue: 0, opacity: 0.8),
                                    radius: 2,
                                    x: 2,
                                    y: 2)
                                .foregroundColor(Color(red:0.5, green: 1.0, blue: 0.5))

                            Text("\(String(format: "%.2f", sysLink.currentFrameTimeMs))ms")
                                .font(Font.system(size: 12).monospaced())
                                .shadow(
                                    color: Color(red: 0, green: 0, blue: 0, opacity: 0.8),
                                    radius: 2,
                                    x: 2,
                                    y: 2)
                                .foregroundColor(Color(red:0.5, green: 1.0, blue: 0.5))
                        }
                        .padding(.trailing)
                        .padding(.top, layoutState.topPadding)
                        .allowsHitTesting(false)
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
                let view = KMetalView(sysLink)
                view.translatesAutoresizingMaskIntoConstraints = false
                view.autoResizeDrawable = true
                return view
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

struct BackgroundClearView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
