import UIKit

// todo: handle orientation lock/changes
extension KSysLink: UIApplicationDelegate {
    //    static var orientationLock = UIInterfaceOrientationMask.landscape
    //
    //    public func application(
    //        _ application: UIApplication,
    //        supportedInterfaceOrientationsFor window: UIWindow?
    //    ) -> UIInterfaceOrientationMask {
    //        return Self.orientationLock
    //    }
    
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        //        let orientation = UIInterfaceOrientationMask.landscapeRight
        //        var orientationUpdated = false
        //        if #available(iOS 16.0, *) {
        //            if let windowScene: UIWindowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        //                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        //                orientationUpdated = true
        //            }
        //        }
        //        if !orientationUpdated {
        //            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        //        }
        self.applicationFinishedLaunching = true
        return true
    }

    static func orientationToString(orientation: UIInterfaceOrientation) -> String {
        switch orientation {
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        default: return "unknown"
        }
    }
}
