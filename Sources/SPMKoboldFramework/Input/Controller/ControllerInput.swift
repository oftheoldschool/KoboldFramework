import Foundation
import SwiftUI

public class KControllerScreenButtonGestureRecognizer : UITapGestureRecognizer, UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }
}

public class KControllerInput {
    var eventQueue: KQueue<KEvent>

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue
    }

    var stickSizePixels: Int!
    var socketSizePixels: Int!

    var leftControlStick: KUIControlStick!
    var rightControlStick: KUIControlStick!

    private func buzz() {
        let feedbackGenerator = UIImpactFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred(intensity: 1)
        feedbackGenerator.prepare()
    }

    public func registerWithView(
        view: UIView,
        visibleControls: Bool
    ) {
        let boundsRect = (width: Float(view.bounds.width), height: Float(view.bounds.height))

        var uiScale = 0.002 * Float(boundsRect.width)
        if boundsRect.height > boundsRect.width {
            uiScale *= 1.5
        }

        let lineAlpha = visibleControls ? 0.2 : 0
        let fillAlpha = visibleControls ? 0.1 : 0

        let padding: Float = 20
        let buttonSizePixels: Float = 25
        let startButtonSizePixels: Float = 30
        stickSizePixels = 40
        socketSizePixels = 60

        let leftStickPosition = (
            x: Int(padding * 2.5 * uiScale),
            y: Int(boundsRect.height - (Float(stickSizePixels) + padding * 2) * uiScale))
        leftControlStick = KUIControlStick(
            position: leftStickPosition,
            stickRadiusInPixels: Int(Float(stickSizePixels) * uiScale),
            socketRadiusInPixels: Int(Float(socketSizePixels) * uiScale),
            strokeColor: .init(white: 1, alpha: lineAlpha),
            strokeWidth: 4,
            fillColor: UIColor(white: 1, alpha: fillAlpha))
        view.addSubview(leftControlStick)

        let rightStickPosition = (
            x: Int(boundsRect.width - (Float(stickSizePixels) + padding * 2.5) * uiScale),
            y: Int(boundsRect.height - (Float(stickSizePixels) + padding * 2) * uiScale))

        rightControlStick = KUIControlStick(
            position: rightStickPosition,
            stickRadiusInPixels: Int(Float(stickSizePixels) * uiScale),
            socketRadiusInPixels: Int(Float(socketSizePixels) * uiScale),
            strokeColor: UIColor(white: 1, alpha: lineAlpha),
            strokeWidth: 4,
            fillColor: UIColor(white: 1, alpha: fillAlpha))

        view.addSubview(rightControlStick)

        let buttonAView = KUICircle(
            position: (
                x: Int(boundsRect.width - (Float(buttonSizePixels * 2) + padding * 2) * uiScale),
                y: Int(boundsRect.height - (Float(buttonSizePixels * 2) + padding * 3.5) * uiScale)),
            radiusInPixels: Int(Float(buttonSizePixels) * uiScale),
            strokeColor: UIColor(white: 1, alpha: lineAlpha),
            strokeWidth: 4,
            fillColor: UIColor(white: 1, alpha: fillAlpha))

        view.addSubview(buttonAView)

        let buttonBView = KUICircle(
            position: (
                x: Int(boundsRect.width - (Float(buttonSizePixels * 2) + padding * 0.25) * uiScale),
                y: Int(boundsRect.height - (Float(buttonSizePixels * 2) + padding * 4.25) * uiScale)),
            radiusInPixels: Int(Float(buttonSizePixels) * uiScale),
            strokeColor: UIColor(white: 1, alpha: lineAlpha),
            strokeWidth: 4,
            fillColor: UIColor(white: 1, alpha: fillAlpha))

        view.addSubview(buttonBView)

        let buttonXView = KUICircle(
            position: (
                x: Int(boundsRect.width - (Float(buttonSizePixels * 2) + padding * 2.75) * uiScale),
                y: Int(boundsRect.height - (Float(buttonSizePixels * 2) + padding * 5.25) * uiScale)),
            radiusInPixels: Int(Float(buttonSizePixels) * uiScale),
            strokeColor: UIColor(white: 1, alpha: lineAlpha),
            strokeWidth: 4,
            fillColor: UIColor(white: 1, alpha: fillAlpha))
        view.addSubview(buttonXView)

        let buttonYView = KUICircle(
            position: (
                x: Int(boundsRect.width - (Float(buttonSizePixels * 2) + padding * 1) * uiScale),
                y: Int(boundsRect.height - (Float(buttonSizePixels * 2) + padding * 6) * uiScale)),
            radiusInPixels: Int(Float(buttonSizePixels) * uiScale),
            strokeColor: UIColor(white: 1, alpha: lineAlpha),
            strokeWidth: 4,
            fillColor: UIColor(white: 1, alpha: fillAlpha))
        view.addSubview(buttonYView)

        let horizontalAdjustment = (Float(socketSizePixels) - Float(startButtonSizePixels)) * 0.5
        let buttonStartView = KUIRectangle(
            position: (
                x: Int(padding * 2.5 * uiScale + horizontalAdjustment * uiScale),
                y: Int(boundsRect.height - (Float(buttonSizePixels * 2) + padding * 4.25) * uiScale)),
            widthInPixels: Int(Float(startButtonSizePixels) * uiScale),
            heightInpixels: Int(Float(startButtonSizePixels) * uiScale * 0.4),
            strokeColor: UIColor(white: 1, alpha: lineAlpha),
            strokeWidth: 4,
            fillColor: UIColor(white: 1, alpha: fillAlpha))
        view.addSubview(buttonStartView)

        // this is taking priority over the sticks: https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/coordinating_multiple_gesture_recognizers/preferring_one_gesture_over_another
        let screenButtonGesture = KControllerScreenButtonGestureRecognizer(target: self, action: #selector(screenButton))
        screenButtonGesture.delegate = screenButtonGesture
        screenButtonGesture.numberOfTouchesRequired = 1
        screenButtonGesture.name = "Screen Button Gesture Recognizer"
        view.addGestureRecognizer(screenButtonGesture)

        let buttonStartGesture = UITapGestureRecognizer(target: self, action: #selector(buttonStart))
        buttonStartGesture.numberOfTouchesRequired = 1
        buttonStartGesture.name = "Button Start Gesture Recognizer"
        buttonStartView.addGestureRecognizer(buttonStartGesture)

        let leftControlStickPan = UIPanGestureRecognizer(target: self, action: #selector(leftControlStickPan))
        leftControlStickPan.minimumNumberOfTouches = 1
        leftControlStickPan.name = "Left Stick Gesture Recognizer"
        leftControlStick.addGestureRecognizer(leftControlStickPan)

        let rightControlStickPan = UIPanGestureRecognizer(target: self, action: #selector(rightControlStickPan))
        rightControlStickPan.minimumNumberOfTouches = 1
        rightControlStickPan.name = "Right Stick Gesture Recognizer"
        rightControlStick.addGestureRecognizer(rightControlStickPan)

        let buttonAGesture = UILongPressGestureRecognizer(target: self, action: #selector(buttonA))
        buttonAGesture.minimumPressDuration = 0.01
        buttonAGesture.numberOfTouchesRequired = 1
        buttonAGesture.name = "Button A Gesture Recognizer"
        buttonAView.addGestureRecognizer(buttonAGesture)

        let buttonBGesture = UILongPressGestureRecognizer(target: self, action: #selector(buttonB))
        buttonBGesture.minimumPressDuration = 0.01
        buttonBGesture.numberOfTouchesRequired = 1
        buttonBGesture.name = "Button B Gesture Recognizer"
        buttonBView.addGestureRecognizer(buttonBGesture)

        let buttonXGesture = UILongPressGestureRecognizer(target: self, action: #selector(buttonX))
        buttonXGesture.minimumPressDuration = 0.01
        buttonXGesture.numberOfTouchesRequired = 1
        buttonXGesture.name = "Button X Gesture Recognizer"
        buttonXView.addGestureRecognizer(buttonXGesture)

        let buttonYGesture = UILongPressGestureRecognizer(target: self, action: #selector(buttonY))
        buttonYGesture.minimumPressDuration = 0.01
        buttonYGesture.numberOfTouchesRequired = 1
        buttonYGesture.name = "Button Y Gesture Recognizer"
        buttonYView.addGestureRecognizer(buttonYGesture)
    }

    @objc public func screenButton(gesture: KControllerScreenButtonGestureRecognizer) {
        let rawPosition = gesture.location(in: gesture.view)

        switch gesture.state {
        case .ended:
            buzz()

            eventQueue.enqueue(item: .input(
                .controller(
                    .screenTap(
                        KControllerEventScreenTap(
                            state: .pressed,
                            position: rawPosition.toFloatPair())))))
            eventQueue.enqueue(item: .input(
                .controller(
                    .screenTap(
                        KControllerEventScreenTap(
                            state: .released,
                            position: rawPosition.toFloatPair())))))
        default:
            break
        }
    }

    @objc public func buttonA(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            buzz()

            eventQueue.enqueue(item: .input(
                        .controller(
                            .button(
                                KControllerEventButton(
                                    button: .buttonA,
                                    state: .pressed)))))
        case .ended:
            eventQueue.enqueue(item: .input(
                        .controller(
                            .button(
                                KControllerEventButton(
                                    button: .buttonA,
                                    state: .released)))))
        default:
            break
        }
    }

    @objc public func buttonB(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            buzz()

            eventQueue.enqueue(item: .input(
                .controller(
                    .button(
                        KControllerEventButton(
                            button: .buttonB,
                            state: .pressed)))))
        case .ended:
            eventQueue.enqueue(item: .input(
                .controller(
                    .button(
                        KControllerEventButton(
                            button: .buttonB,
                            state: .released)))))
        default:
            break
        }
    }

    @objc public func buttonX(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            buzz()

            eventQueue.enqueue(item: .input(
                .controller(
                    .button(
                        KControllerEventButton(
                            button: .buttonX,
                            state: .pressed)))))
        case .ended:
            eventQueue.enqueue(item: .input(
                .controller(
                    .button(
                        KControllerEventButton(
                            button: .buttonX,
                            state: .released)))))
        default:
            break
        }
    }

    @objc public func buttonY(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            buzz()

            eventQueue.enqueue(item: .input(
                .controller(.button(
                    KControllerEventButton(
                        button: .buttonY,
                        state: .pressed)))))
        case .ended:
            eventQueue.enqueue(item: .input(
                .controller(
                    .button(
                        KControllerEventButton(
                            button: .buttonY,
                            state: .released)))))
        default:
            break
        }
    }

    @objc public func buttonStart(gesture: UITapGestureRecognizer) {
        switch gesture.state {
        case .ended:
            buzz()

            eventQueue.enqueue(item: .input(
                .controller(
                    .button(
                        KControllerEventButton(
                            button: .buttonStart,
                            state: .pressed)))))
            eventQueue.enqueue(item: .input(
                .controller(
                    .button(
                        KControllerEventButton(
                            button: .buttonStart,
                            state: .released)))))
        default:
            break
        }
    }

    @objc
    func leftControlStickPan(gesture: UIPanGestureRecognizer) {
        var touchPosition = gesture.translation(in: gesture.view)
        let distFromBase = sqrt(
            pow(Float(touchPosition.x), 2) +
            pow(Float(touchPosition.y), 2))

        let maxOffset = CGFloat(stickSizePixels) * 0.6
        if distFromBase > 0 {
            let scale = CGFloat(distFromBase) >= maxOffset ? maxOffset / CGFloat(distFromBase) : 1
            touchPosition.x *= scale
            touchPosition.y *= scale
        }

        let scaledTouchPosition = CGPoint(
            x: touchPosition.x / maxOffset,
            y: touchPosition.y / maxOffset).toFloatPair()

        let stickView = leftControlStick.stickView!
        switch gesture.state {
        case .began:
            stickView.frame.origin.x = CGFloat(leftControlStick.stickBasePos.x) + touchPosition.x
            stickView.frame.origin.y = CGFloat(leftControlStick.stickBasePos.y) + touchPosition.y
            eventQueue.enqueue(item: .input(
                .controller(
                    .stick(
                        KControllerEventStick(
                            stick: .stickLeft,
                            state: .began,
                            offset: scaledTouchPosition)))))
        case .changed:
            stickView.frame.origin.x = CGFloat(leftControlStick.stickBasePos.x) + touchPosition.x
            stickView.frame.origin.y = CGFloat(leftControlStick.stickBasePos.y) + touchPosition.y
            eventQueue.enqueue(item:
                    .input(
                        .controller(
                            .stick(
                                KControllerEventStick(
                                    stick: .stickLeft,
                                    state: .changed,
                                    offset: scaledTouchPosition)))))
        case .ended, .cancelled, .failed:
            stickView.frame.origin.x = CGFloat(leftControlStick.stickBasePos.x)
            stickView.frame.origin.y = CGFloat(leftControlStick.stickBasePos.y)
            eventQueue.enqueue(item:
                    .input(
                        .controller(
                            .stick(
                                KControllerEventStick(
                                    stick: .stickLeft,
                                    state: .ended,
                                    offset: scaledTouchPosition)))))
        default:
            break
        }
    }

    @objc
    func rightControlStickPan(gesture: UIPanGestureRecognizer) {
        var touchPosition = gesture.translation(in: gesture.view)
        let distFromBase = sqrt(
            pow(Float(touchPosition.x), 2) +
            pow(Float(touchPosition.y), 2))

        let maxOffset = CGFloat(stickSizePixels) * 0.6
        if distFromBase > 0 {
            let scale = CGFloat(distFromBase) >= maxOffset ? maxOffset / CGFloat(distFromBase) : 1
            touchPosition.x *= scale
            touchPosition.y *= scale
        }

        let scaledTouchPosition = CGPoint(
            x: touchPosition.x / maxOffset,
            y: touchPosition.y / maxOffset).toFloatPair()

        let stickView = rightControlStick.stickView!
        switch gesture.state {
        case .began:
            stickView.frame.origin.x = CGFloat(rightControlStick.stickBasePos.x) + touchPosition.x
            stickView.frame.origin.y = CGFloat(rightControlStick.stickBasePos.y) + touchPosition.y
            eventQueue.enqueue(item:  .input(
                .controller(
                    .stick(
                        KControllerEventStick(
                            stick: .stickRight,
                            state: .began,
                            offset: scaledTouchPosition)))))
        case .changed:
            stickView.frame.origin.x = CGFloat(rightControlStick.stickBasePos.x) + touchPosition.x
            stickView.frame.origin.y = CGFloat(rightControlStick.stickBasePos.y) + touchPosition.y
            eventQueue.enqueue(item: .input(
                .controller(
                    .stick(
                        KControllerEventStick(
                            stick: .stickRight,
                            state: .changed,
                            offset: scaledTouchPosition)))))
        case .ended, .cancelled, .failed:
            stickView.frame.origin.x = CGFloat(rightControlStick.stickBasePos.x)
            stickView.frame.origin.y = CGFloat(rightControlStick.stickBasePos.y)
            eventQueue.enqueue(item: .input(
                .controller(
                    .stick(
                        KControllerEventStick(
                            stick: .stickRight,
                            state: .ended,
                            offset: scaledTouchPosition)))))
        default:
            break
        }
    }
}
