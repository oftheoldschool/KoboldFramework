import SwiftUI

struct BasicLoadingView: View {
    @State
    private var isRotating = 0.0

    private let title: String
    private let foregroundColor: Color
    private let gradientColors: [Color]

    init(
        title: String,
        foregroundColor: (r: Float, g: Float, b: Float),
        gradientColors: [(r: Float, g: Float, b: Float)]
    ) {
        self.title = title
        self.foregroundColor = Color(
            red: Double(foregroundColor.r),
            green: Double(foregroundColor.g),
            blue: Double(foregroundColor.b))
        self.gradientColors = gradientColors.map { color in
            Color(
                red: Double(color.r),
                green: Double(color.g),
                blue: Double(color.b))
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
                    .foregroundColor(foregroundColor)
                    .multilineTextAlignment(.center)
                Image(systemName: "arrow.triangle.2.circlepath.circle")
                    .font(.system(size: 60))
                    .monospaced()
                    .foregroundColor(foregroundColor)
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
                    .foregroundColor(foregroundColor)
            }
        }
    }
}
