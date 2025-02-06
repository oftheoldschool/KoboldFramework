import SwiftUI

public class KModalState: ObservableObject {
    public static let shared = KModalState()

    @Published
    public var presentAnotherView = false

    private init() {}
}

struct KModalView: View {
    @StateObject var modalState = KModalState.shared

    let title: String
    let viewDefinition: any View

    init(title: String, viewDefinition: any View) {
        self.title = title
        self.viewDefinition = viewDefinition
    }

    var body: some View {
        Button(title) {
            modalState.presentAnotherView = true
        }
        .dynamicTypeSize(.large)
        .padding()
        .sheet(isPresented: $modalState.presentAnotherView) {
            VStack {
                HStack {
                    Spacer()
                    Button("Dismiss") {
                        modalState.presentAnotherView = false
                    }
                    .dynamicTypeSize(.large)
                    .fixedSize()
                    .padding([.top, .trailing], 20)
                }
                Text(title)
                    .dynamicTypeSize(.xxxLarge)
                AnyView(viewDefinition)
                    .padding([.all], 20)
            }.presentationDetents([.medium, .large])
                .presentationBackground(Material.ultraThin)
        }
    }
}
