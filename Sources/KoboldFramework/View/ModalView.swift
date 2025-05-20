import SwiftUI

public class KModalState: ObservableObject {
    public static let shared = KModalState()

    @Published
    public var presentAnotherView = false

    private init() {}
}

public struct KModalStyle: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let medium = KModalStyle(rawValue: 1 << 0)
    public static let large = KModalStyle(rawValue: 1 << 1)
    public static let fullScreen = KModalStyle(rawValue: 1 << 2)

    var presentationDetents: Set<PresentationDetent> {
        var detents: Set<PresentationDetent> = []

        if self.contains(.medium) {
            detents.insert(.medium)
        }

        if self.contains(.large) {
            detents.insert(.large)
        }

        if detents.isEmpty {
            detents.insert(.medium)
        }

        return detents
    }
}

struct KModalView: View {
    @StateObject var modalState = KModalState.shared
    @State private var isWindowedMode = false
    @State private var topPadding: CGFloat = 0

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
        .padding(.leading)
        .padding(.top, topPadding)
        .onAppear {
            checkWindowMode()
        }
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didChangeScreenNotification)) { _ in
            checkWindowMode()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResizeNotification)) { _ in
            checkWindowMode()
        }
        #endif
        .modifier(ModalPresentation(
            isPresented: $modalState.presentAnotherView,
            style: style,
            title: title,
            viewDefinition: viewDefinition
        ))
    }

    func checkWindowMode() {
        #if os(macOS)
        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            isWindowedMode = !window.styleMask.contains(.fullScreen)
            topPadding = isWindowedMode ? 44 : 16
        }
        #elseif targetEnvironment(macCatalyst)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screen = scene.screen
            if let window = scene.windows.first {
                let isFullScreen = abs(window.frame.width - screen.bounds.width) < 1 &&
                                  abs(window.frame.height - screen.bounds.height) < 1
                isWindowedMode = !isFullScreen
                topPadding = isWindowedMode ? 44 : 16
            }
        }
        #else
        topPadding = 16
        #endif
    }
}

private struct ModalPresentation: ViewModifier {
    @Binding var isPresented: Bool
    let style: KModalStyle
    let title: String
    let viewDefinition: any View

    func body(content: Content) -> some View {
        if style.contains(.fullScreen) {
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
            .presentationDetents(style.presentationDetents)
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
