import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
#if targetEnvironment(macCatalyst)
    static var configuration = KMacCatalystConfiguration()
#endif

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
#if targetEnvironment(macCatalyst)
        let configuration = Self.configuration
        if configuration.removesTitleBar,
           let titleBar = windowScene.titlebar {
            titleBar.titleVisibility = .hidden
            titleBar.toolbar = nil
        }
        if let sizes = windowScene.sizeRestrictions {
            sizes.allowsFullScreen = configuration.windowControls.allowsFullScreen
            if let preferredWindowSize = configuration.preferredWindowSize {
                sizes.minimumSize = preferredWindowSize.cgSize
                sizes.maximumSize = preferredWindowSize.cgSize
            } else {
                sizes.minimumSize = CGSize(width: 0, height: 0)
                sizes.maximumSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            }
        }
        if let windowingBehaviors = windowScene.windowingBehaviors {
            windowingBehaviors.isClosable = configuration.windowControls.showsCloseButton
            windowingBehaviors.isMiniaturizable = configuration.windowControls.showsMinimizeButton
        }
        KLayoutState.shared.updateTopPadding()
#endif
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
#if targetEnvironment(macCatalyst)
        guard scene is UIWindowScene else { return }
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            KLayoutState.shared.updateTopPadding()
        }
#endif
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        didUpdate previousCoordinateSpace: any UICoordinateSpace,
        interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
        traitCollection previousTraitCollection: UITraitCollection
    ) {
#if targetEnvironment(macCatalyst)
        KLayoutState.shared.updateTopPadding()
#endif
    }
}
