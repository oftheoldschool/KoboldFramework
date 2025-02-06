import UIKit

@IBDesignable
class KUIControlStick: UIView {
    var stickRadius: Int = 40
    var socketRadius: Int = 60
    var strokeColor: UIColor = .clear
    var strokeWidth: Int = 0
    var fillColor: UIColor = .white
    var stickView: UIView? = nil
    var stickBasePos: CGPoint = CGPoint.zero

    init(
        position: (x: Int, y: Int),
        stickRadiusInPixels stickRadius: Int,
        socketRadiusInPixels socketRadius: Int,
        strokeColor: UIColor,
        strokeWidth: Int,
        fillColor: UIColor
    ) {
        self.stickRadius = stickRadius
        self.socketRadius = socketRadius
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.fillColor = fillColor
        super.init(frame: CGRect(
            x: position.x, y: position.y,
            width: socketRadius, height: socketRadius))
        self.clipsToBounds = false
        self.backgroundColor = .clear
        let stickOffset = CGFloat(socketRadius - stickRadius) / 2
        self.stickBasePos = CGPoint(x: stickOffset, y: stickOffset)

        self.addSubview(KUICircle(
            position: (0, 0),
            radiusInPixels: socketRadius,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            fillColor: fillColor))

        let stickView = KUICircle(
            position: (Int(stickBasePos.x), Int(stickBasePos.y)),
            radiusInPixels: stickRadius,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            fillColor: fillColor)
        self.addSubview(stickView)
        self.stickView = stickView
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        self.backgroundColor = .clear
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

@IBDesignable
class KUICircle: UIView {
    var radius: Int = 40
    var strokeColor: UIColor = .clear
    var strokeWidth: Int = 0
    var fillColor: UIColor = .white

    init(
        position: (x: Int, y: Int),
        radiusInPixels radius: Int,
        strokeColor: UIColor,
        strokeWidth: Int,
        fillColor: UIColor
    ) {
        self.radius = radius
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.fillColor = fillColor
        super.init(frame: CGRect(
            x: position.x, y: position.y,
            width: radius, height: radius))
        self.clipsToBounds = false
        self.backgroundColor = .clear
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        self.backgroundColor = .clear
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.setFillColor(self.fillColor.cgColor)
        ctx.fillEllipse(in: CGRect(
            x: 0, y: 0,
            width: radius,
            height: radius))

        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.setLineWidth(CGFloat(strokeWidth))
        ctx.strokeEllipse(in: CGRect(
            x: strokeWidth / 2, y: strokeWidth / 2,
            width: self.radius - self.strokeWidth,
            height: self.radius - self.strokeWidth))
    }
}

@IBDesignable
class KUIRectangle: UIView {
    var width: Int = 100
    var height: Int = 40
    var strokeColor: UIColor = .clear
    var strokeWidth: Int = 0
    var fillColor: UIColor = .white

    init(
        position: (x: Int, y: Int),
        widthInPixels width: Int,
        heightInpixels height: Int,
        strokeColor: UIColor,
        strokeWidth: Int,
        fillColor: UIColor
    ) {
        self.width = width
        self.height = height
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.fillColor = fillColor
        super.init(frame: CGRect(
            x: position.x, y: position.y,
            width: width, height: height))
        self.clipsToBounds = false
        self.backgroundColor = .clear
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        self.backgroundColor = .clear
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let cornerRadius: CGFloat = 8
        let clipPathStroke = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
        ctx.addPath(clipPathStroke)
        ctx.closePath()

        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.setLineWidth(CGFloat(strokeWidth))
        ctx.strokePath()

        let clipPathFill = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
        ctx.addPath(clipPathFill)
        ctx.closePath()
        ctx.setFillColor(self.fillColor.cgColor)
        ctx.fillPath()
    }
}
