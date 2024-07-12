import SwiftUI

struct KModalView: View {
    @State var presentAnotherView = false
    
    let title: String
    let viewDefinition: any View
    
    init(title: String, viewDefinition: any View) {
        self.title = title
        self.viewDefinition = viewDefinition
    }
    
    var body: some View {
        Button(title) {
            presentAnotherView = true
        }
        .padding()
        .sheet(isPresented: $presentAnotherView) {
            VStack {
                HStack {
                    Spacer()
                    Button("Dismiss") {
                        presentAnotherView = false
                    }
                    .fixedSize().padding([.top, .trailing], 20)
                }
                Text(title).font(.title)
                AnyView(viewDefinition)
                    .padding([.all], 20)
            }.presentationDetents([.medium, .large])
                .presentationBackground(Material.ultraThin)
        }
    }
}
