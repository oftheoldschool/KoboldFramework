import SwiftUI
import Metal

public class KLayoutState: ObservableObject {
    public static let shared = KLayoutState()

    @Published
    public var topPadding: CGFloat = 16

    @Published
    public var showFPS: Bool = true

    @Published
    public var showAppMemory: Bool = false

    @Published
    public var showGPUMemory: Bool = false

    @Published
    public var showVersion: Bool = true

    @Published
    public var showScreenshotButton: Bool = true

    @Published
    public var showSettingsButton: Bool = true

    /// When true, screenshots include the game HUD (annotations, orbit progress,
    /// dialog, title). Default on.
    @Published
    public var screenshotIncludeHUD: Bool = true

    /// When true, screenshots include the pause/status menu overlay. Default off.
    @Published
    public var screenshotIncludeMenu: Bool = false

    /// Transient flag set only for the duration of a screenshot capture draw so
    /// the renderer can filter overlay layers for that single frame.
    public var screenshotPassActive: Bool = false

    /// The exact drawable texture rendered by the screenshot-capture frame,
    /// handed off by the graphics system so the screenshot manager reads the
    /// freshly-rendered (filtered) frame instead of a rotated pooled drawable.
    public var screenshotTexture: MTLTexture?

    public func update(
        showFPSToggle: Bool? = nil,
        showAppMemoryToggle: Bool? = nil,
        showGPUMemoryToggle: Bool? = nil,
        showVersionToggle: Bool? = nil,
        showScreenshotButton: Bool? = nil,
        showSettingsButton: Bool? = nil
    ) {
        self.showFPS = showFPSToggle ?? self.showFPS
        self.showAppMemory = showAppMemoryToggle ?? self.showAppMemory
        self.showGPUMemory = showGPUMemoryToggle ?? self.showGPUMemory
        self.showVersion = showVersionToggle ?? self.showVersion
        self.showScreenshotButton = showScreenshotButton ?? self.showScreenshotButton
        self.showSettingsButton = showSettingsButton ?? self.showSettingsButton
    }

    private init() {}

    public func updateTopPadding() {
        checkWindowMode()
    }

    private func checkWindowMode() {
        #if os(macOS)
        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            let isWindowedMode = !window.styleMask.contains(.fullScreen)
            topPadding = isWindowedMode ? 44 : 16
        }
        #elseif targetEnvironment(macCatalyst)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screen = scene.screen
            if let window = scene.windows.first {
                let isFullScreen = abs(window.frame.width - screen.bounds.width) < 1 &&
                                  abs(window.frame.height - screen.bounds.height) < 1
                let isWindowedMode = !isFullScreen
                topPadding = isWindowedMode ? 44 : 16
            }
        }
        #else
        topPadding = 16
        #endif
    }
}
