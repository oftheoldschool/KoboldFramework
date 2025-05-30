import SwiftUI

public struct CustomTabView: View {
    @Binding private var selection: Int
    private var tabItems: [CustomTabItem] = []

    public init(selection: Binding<Int>) {
        self._selection = selection
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(0..<tabItems.count, id: \.self) { index in
                    tabItems[index].view
                        .opacity(selection == index ? 1 : 0)
                        .allowsHitTesting(selection == index)
                }
            }

            HStack(spacing: 0) {
                ForEach(0..<tabItems.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            selection = index
                        }
                    }) {
                        VStack(spacing: 4) {
                            tabItems[index].icon
                                .imageScale(.large)

                            Text(tabItems[index].title)
                                .font(.caption2)
                        }
                        .foregroundColor(selection == index ? .accentColor : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(UIColor.separator)),
                alignment: .top
            )
        }
    }

    public func tabItem(_ title: String, systemImage: String, view: AnyView) -> CustomTabView {
        var copy = self
        copy.tabItems.append(
            CustomTabItem(
                title: title,
                icon: Image(systemName: systemImage),
                view: view
            )
        )
        return copy
    }
}

public struct CustomTabItem {
    public let title: String
    public let icon: Image
    public let view: AnyView
}
