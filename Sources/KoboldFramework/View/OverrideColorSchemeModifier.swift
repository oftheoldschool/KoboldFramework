import SwiftUI

struct OverrideColorSchemeModifier: ViewModifier {
    let colorScheme: ColorScheme?
    func body(content: Content) -> some View {
        if let c = colorScheme {
            content.preferredColorScheme(c)
        } else {
            content
        }
    }
}

extension View {
    func overrideColorScheme(colorScheme: ColorScheme?) -> some View {
        modifier(OverrideColorSchemeModifier(colorScheme: colorScheme))
    }
}
