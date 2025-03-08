import SwiftUI

public class KModalState: ObservableObject {
    public static let shared = KModalState()

    @Published
    public var presentAnotherView = false

    private init() {}
}

public enum KModalStyle {
    case medium
    case large
    case fullScreen
}

struct KModalView: View {
    @StateObject var modalState = KModalState.shared

    let title: String
    let viewDefinition: any View
    let style: KModalStyle

    init(title: String, viewDefinition: any View, style: KModalStyle) {
        self.title = title
        self.viewDefinition = viewDefinition
        self.style = style
    }

    var body: some View {
        Button(title) {
            modalState.presentAnotherView = true
        }
        .dynamicTypeSize(.large)
        .padding()
        .modifier(ModalPresentation(
            isPresented: $modalState.presentAnotherView,
            style: style,
            title: title,
            viewDefinition: viewDefinition
        ))
    }
}

private struct ModalPresentation: ViewModifier {
    @Binding var isPresented: Bool
    let style: KModalStyle
    let title: String
    let viewDefinition: any View

    func body(content: Content) -> some View {
        if style == .fullScreen {
            content.modifier(
                FullScreenModal(isPresented: $isPresented, title: title, viewDefinition: viewDefinition)
            )
        } else {
            content.modifier(
                SheetModal(isPresented: $isPresented, style: style, title: title, viewDefinition: viewDefinition)
            )
        }
    }
}

private struct SheetModal: ViewModifier {
    @Binding var isPresented: Bool
    let style: KModalStyle
    let title: String
    let viewDefinition: any View

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            VStack {
                HStack {
                    Spacer()
                    Button("Dismiss") {
                        isPresented = false
                    }
                    .dynamicTypeSize(.large)
                    .fixedSize()
                    .padding([.top, .trailing], 20)
                }
                Text(title)
                    .dynamicTypeSize(.xxxLarge)
                AnyView(viewDefinition)
                    .padding([.all], 20)
            }
            .presentationDetents(style == .medium ? [.medium] : [.large])
            .presentationBackground(Material.ultraThin)
        }
    }
}

private struct FullScreenModal: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let viewDefinition: any View

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $isPresented) {
            VStack {
                HStack {
                    Spacer()
                    Button("Dismiss") {
                        isPresented = false
                    }
                    .dynamicTypeSize(.large)
                    .fixedSize()
                    .padding([.top, .trailing], 20)
                }
                Text(title)
                    .dynamicTypeSize(.xxxLarge)
                AnyView(viewDefinition)
                    .padding([.all], 20)
            }
        }
    }
}
