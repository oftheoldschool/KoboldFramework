import Foundation
import UIKit

public class KTapInput {
    let eventQueue: KQueue<KEvent>

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue
    }

    public func registerWithView(view: UIView) {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        view.addGestureRecognizer(tapGestureRecognizer)

        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapGesture))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGestureRecognizer)

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture))
        longPressGestureRecognizer.minimumPressDuration = 0.5
        longPressGestureRecognizer.numberOfTouchesRequired = 1

        view.addGestureRecognizer(longPressGestureRecognizer)
    }

    @objc public func tapGesture(gesture: UITapGestureRecognizer) {
        let pos = gesture.location(in: gesture.view).toFloatPair()
        switch gesture.state {
        case .began:
            eventQueue.enqueue(item: .input(
                .tap(
                    KTapEvent(
                        state: .began,
                        type: .tap,
                        position: pos))))
        case .ended, .failed, .cancelled:
            eventQueue.enqueue(item: .input(
                .tap(
                    KTapEvent(
                        state: .ended,
                        type: .tap,
                        position: pos))))
        default:
            break
        }
    }

    @objc public func doubleTapGesture(gesture: UITapGestureRecognizer) {
        let pos = gesture.location(in: gesture.view).toFloatPair()
        switch gesture.state {
        case .began:
            eventQueue.enqueue(item: .input(
                .tap(
                    KTapEvent(
                        state: .began,
                        type: .doubleTap,
                        position: pos))))
        case .ended, .failed, .cancelled:
            eventQueue.enqueue(item: .input(
                .tap(
                    KTapEvent(
                        state: .ended,
                        type: .doubleTap,
                        position: pos))))
        default:
            break
        }
    }

    @objc public func longPressGesture(gesture: UILongPressGestureRecognizer) {
        let pos = gesture.location(in: gesture.view).toFloatPair()
        switch gesture.state {
        case .began:
            eventQueue.enqueue(item: .input(
                .tap(
                    KTapEvent(
                        state: .began,
                        type: .longPress,
                        position: pos))))
        case .ended, .failed, .cancelled:
            eventQueue.enqueue(item: .input(
                .tap(
                    KTapEvent(
                        state: .ended,
                        type: .longPress,
                        position: pos))))
        default:
            break
        }
    }
}
