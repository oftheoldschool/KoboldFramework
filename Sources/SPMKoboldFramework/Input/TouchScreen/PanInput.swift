import Foundation
import UIKit

public class KPanInput {
    var eventQueue: KQueue<KEvent>

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue
    }

    public func registerWithView(view: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan))
        view.addGestureRecognizer(panGesture)
    }

    @objc public func pan(
        gesture: UIPanGestureRecognizer
    ) {
        let pos = gesture.location(in: gesture.view).toFloatPair()
        switch gesture.state {
        case .began:
            eventQueue.enqueue(item: .input(
                .pan(
                    KPanEvent(
                        state: .began, 
                        position: pos))))
        case .changed:
            eventQueue.enqueue(item: .input(
                .pan(
                    KPanEvent(
                        state: .panning, 
                        position: pos))))
        case .ended, .failed, .cancelled:
            eventQueue.enqueue(item: .input(
                .pan(
                    KPanEvent(
                        state: .ended, 
                        position: pos))))
        default:
            break
        }
    }
}
