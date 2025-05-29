import UIKit

public enum KDeviceType {
    case unsupported
    case phone
    case pad
    case mac

    public static var current: KDeviceType {
        get {
#if os(macOS) || targetEnvironment(macCatalyst)
            return .mac
#else
            if UIDevice.current.userInterfaceIdiom == .pad {
                return .pad
            } else if UIDevice.current.userInterfaceIdiom == .phone {
                return .phone
            } else {
                return .unsupported
            }
#endif
        }
    }
}

public enum KOperatingSystem {
    case unsupported
    case ios
    case macos

    public static func current() -> KOperatingSystem {
#if os(macOS) || targetEnvironment(macCatalyst)
        return .macos
#elseif os(iOS)
        return .ios
#else
        return .unsupported
#endif
    }
}
