import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
#if targetEnvironment(macCatalyst)
        if let titleBar = windowScene.titlebar,
           let sizes = windowScene.sizeRestrictions {
            titleBar.titleVisibility = .hidden
            titleBar.toolbar = nil
            sizes.allowsFullScreen = true
//            sizes.minimumSize = windowScene.screen.bounds.size
//            sizes.maximumSize = windowScene.screen.bounds.size
        }
#endif
    }
}
