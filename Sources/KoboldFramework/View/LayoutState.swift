import SwiftUI

public class KLayoutState: ObservableObject {
    public static let shared = KLayoutState()

    @Published
    public var topPadding: CGFloat = 16

    @Published
    public var showFPS: Bool = true

    @Published
    public var showVersion: Bool = true

    @Published
    public var showScreenshotButton: Bool = true

    @Published
    public var showSettingsButton: Bool = true

    public func update(
        showFPSToggle: Bool? = nil,
        showVersionToggle: Bool? = nil,
        showScreenshotButton: Bool? = nil,
        showSettingsButton: Bool? = nil
    ) {
        self.showFPS = showFPSToggle ?? self.showFPS
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
