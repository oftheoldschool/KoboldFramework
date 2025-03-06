import SwiftUI

public extension Color {
    static let adaptiveGray = Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor.lightGray
        case .light, .unspecified:
            return UIColor.darkGray
        @unknown default:
            return UIColor.darkGray
        }
    })
}
