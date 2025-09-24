import SwiftUI

public struct KScreenshotButton: View {
    @EnvironmentObject private var screenshotManager: KScreenshotManager
    
    private let config: KScreenshotButtonConfig
    private let buttonStyle: KScreenshotButtonStyle
    
    public init(
        config: KScreenshotButtonConfig = KScreenshotButtonConfig(),
        style: KScreenshotButtonStyle = .default
    ) {
        self.config = config
        self.buttonStyle = style
    }
    
    public var body: some View {
        Button(role: nil, action: captureScreenshot) {
            HStack(spacing: 8) {
                Image(systemName: buttonStyle.iconName)
                    .font(buttonStyle.iconFont)
                
                if buttonStyle.showTitle {
                    Text(buttonStyle.title)
                        .font(buttonStyle.titleFont)
                }
            }
            .foregroundColor(buttonStyle.foregroundColor)
            .padding(buttonStyle.padding)
            .background(buttonStyle.backgroundColor)
            .cornerRadius(buttonStyle.cornerRadius)
            .shadow(
                color: buttonStyle.shadowColor,
                radius: buttonStyle.shadowRadius,
                x: buttonStyle.shadowOffset.width,
                y: buttonStyle.shadowOffset.height
            )
        }
    }
    
    private func captureScreenshot() {
        Task { @MainActor in
            guard let capturedImage = screenshotManager.captureScreenshot() else {
                return
            }

            config.customAction?(capturedImage)
            
            screenshotManager.saveScreenshot(capturedImage) { success, error in
                Task { @MainActor in
                    
                }
            }
        }
    }
}

public struct KScreenshotButtonStyle {
    public let iconName: String
    public let iconFont: Font
    public let title: String
    public let titleFont: Font
    public let showTitle: Bool
    public let foregroundColor: Color
    public let backgroundColor: Color
    public let padding: EdgeInsets
    public let cornerRadius: CGFloat
    public let shadowColor: Color
    public let shadowRadius: CGFloat
    public let shadowOffset: CGSize
    
    public init(
        iconName: String = "camera",
        iconFont: Font = .title2,
        title: String = "Screenshot",
        titleFont: Font = .caption,
        showTitle: Bool = false,
        foregroundColor: Color = .white,
        backgroundColor: Color = Color.black.opacity(0.6),
        padding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
        cornerRadius: CGFloat = 8,
        shadowColor: Color = Color.black.opacity(0.3),
        shadowRadius: CGFloat = 2,
        shadowOffset: CGSize = CGSize(width: 1, height: 1)
    ) {
        self.iconName = iconName
        self.iconFont = iconFont
        self.title = title
        self.titleFont = titleFont
        self.showTitle = showTitle
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
    }
    
    public static let `default` = KScreenshotButtonStyle()
    
    public static let compact = KScreenshotButtonStyle(
        iconFont: .title3,
        showTitle: false,
        padding: EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6),
        cornerRadius: 6
    )
    
    public static let large = KScreenshotButtonStyle(
        iconFont: .title,
        titleFont: .body,
        showTitle: true,
        padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
        cornerRadius: 12
    )
}
