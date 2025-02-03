import SwiftUI

struct DefaultFontModifier: ViewModifier {
    let font: Font?
    func body(content: Content) -> some View {
        if let f = font {
            content.font(f)
        } else {
            content
        }
    }
}

extension View {
    func defaultFont(font: Font?) -> some View {
        modifier(DefaultFontModifier(font: font))
    }
}
