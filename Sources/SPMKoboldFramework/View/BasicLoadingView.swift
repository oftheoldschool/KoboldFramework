import SwiftUI

struct BasicLoadingView: View {
    @State
    private var isRotating = 0.0
    
    private let title: String
    private let gradientColors: [Color]
    
    init(
        title: String,
        gradientColors: [(r: Float, g: Float, b: Float)] = [
            (r: 0.5, g: 0.667, b: 1),
            (r: 0.75, g: 0.334, b: 1),
        ]
    ) {
        self.title = title
        self.gradientColors = gradientColors.map { color in
            Color(red: Double(color.r), green: Double(color.g), blue: Double(color.b))
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .top, endPoint: .bottom)
            VStack {
                Text(title)
                    .font(.system(size: 48).bold().monospaced())
                    .padding(.bottom)
                    .foregroundColor(Color(red:0.5, green: 1.0, blue: 0.5))
                Image(systemName: "arrow.triangle.2.circlepath.circle")
                    .font(.system(size: 60))
                    .monospaced()
                    .foregroundColor(Color(red:0.5, green: 1.0, blue: 0.5))
                    .rotationEffect(.degrees(isRotating))
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false)) {
                                isRotating = 360
                            }
                    }
                Text("loading...")
                    .font(.system(size: 36).bold().monospaced())
                    .padding(.top)
                    .foregroundColor(Color(red:0.5, green: 1.0, blue: 0.5))
            }
        }
    }
}
