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
    @StateObject var layoutState = KLayoutState.shared

    let title: String
    let showTitle: Bool
    let showButton: Bool
    let dismissButtonTitle: String
    let showDismissButton: Bool
    let viewDefinition: any View
    let style: KModalStyle
    let deviceStyleOverrides: [KDeviceType: KModalStyle]

    init(
        title: String,
        showTitle: Bool,
        showButton: Bool,
        dismissButtonTitle: String,
        showDismissButton: Bool,
        viewDefinition: any View,
        style: KModalStyle,
        deviceStyleOverrides: [KDeviceType: KModalStyle]
    ) {
        self.title = title
        self.showTitle = showTitle
        self.showButton = showButton
        self.dismissButtonTitle = dismissButtonTitle
        self.showDismissButton = showDismissButton
        self.viewDefinition = viewDefinition
        self.style = style
        self.deviceStyleOverrides = deviceStyleOverrides
    }

    var body: some View {
        Button(title) {
            modalState.presentAnotherView = true
        }
        .allowsHitTesting(true)
        .foregroundStyle(showButton && layoutState.showSettingsButton ? Color.accentColor : Color.clear)
        .keyboardShortcut(KeyEquivalent(Character(",")), modifiers: .command)
        .dynamicTypeSize(.large)
        .padding(.leading)
        .padding(.top, layoutState.topPadding)
        .onAppear {
            layoutState.updateTopPadding()
        }
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didChangeScreenNotification)) { _ in
            layoutState.updateTopPadding()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResizeNotification)) { _ in
            layoutState.updateTopPadding()
        }
        #endif
        .modifier(ModalPresentation(
            isPresented: $modalState.presentAnotherView,
            style: style,
            title: title,
            showTitle: showTitle,
            dismissButtonTitle: dismissButtonTitle,
            showDismissButton: showDismissButton,
            viewDefinition: viewDefinition,
            deviceStyleOverrides: deviceStyleOverrides
        ))
    }
}

private struct ModalPresentation: ViewModifier {
    @Binding var isPresented: Bool
    let style: KModalStyle
    let title: String
    let showTitle: Bool
    let dismissButtonTitle: String
    let showDismissButton: Bool
    let viewDefinition: any View
    let deviceStyleOverrides: [KDeviceType: KModalStyle]

    func body(content: Content) -> some View {
        let resolvedStyle = deviceStyleOverrides[KDeviceType.current] ?? style

        if resolvedStyle.contains(.fullScreen) {
            content.modifier(
                FullScreenModal(
                    isPresented: $isPresented,
                    title: title,
                    showTitle: showTitle,
                    dismissButtonTitle: dismissButtonTitle,
                    showDismissButton: showDismissButton,
                    viewDefinition: viewDefinition)
            )
        } else {
            content.modifier(
                SheetModal(
                    isPresented: $isPresented,
                    style: resolvedStyle,
                    title: title,
                    showTitle: showTitle,
                    dismissButtonTitle: dismissButtonTitle,
                    showDismissButton: showDismissButton,
                    viewDefinition: viewDefinition
                )
            )
        }
    }
}

private struct SheetModal: ViewModifier {
    @Binding var isPresented: Bool
    let style: KModalStyle
    let title: String
    let showTitle: Bool
    let dismissButtonTitle: String
    let showDismissButton: Bool
    let viewDefinition: any View

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            VStack {
                if showDismissButton {
                    HStack {
                        Spacer()
                        Button(dismissButtonTitle) {
                            isPresented = false
                        }
                        .dynamicTypeSize(.large)
                        .fixedSize()
                        .padding([.top, .trailing], 20)
                    }
                }
                if showTitle {
                    Text(title)
                        .dynamicTypeSize(.xxxLarge)
                }
                AnyView(viewDefinition)
            }
            .presentationDetents(style.presentationDetents)
            .presentationBackground(Material.ultraThin)
        }
    }
}

private struct FullScreenModal: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let showTitle: Bool
    let dismissButtonTitle: String
    let showDismissButton: Bool
    let viewDefinition: any View

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $isPresented) {
            VStack {
                if showDismissButton {
                    HStack {
                        Spacer()
                        Button(dismissButtonTitle) {
                            isPresented = false
                        }
                        .dynamicTypeSize(.large)
                        .fixedSize()
                        .padding([.top, .trailing], 20)
                    }
                }
                if showTitle {
                    Text(title)
                        .dynamicTypeSize(.xxxLarge)
                }
                AnyView(viewDefinition)
                    .padding([.all], 20)
            }
        }
    }
}
