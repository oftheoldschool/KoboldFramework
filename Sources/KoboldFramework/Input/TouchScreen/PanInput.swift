import Foundation
import UIKit

public class KPanInput {
    var eventQueue: KQueue<KEvent>
    private weak var registeredView: UIView?
    private var panGestureRecognizer: UIPanGestureRecognizer?

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue
    }

    public func registerWithView(view: UIView) {
        if registeredView === view {
            return
        }
        unregisterFromView()

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan))
        view.addGestureRecognizer(panGesture)
        panGestureRecognizer = panGesture
        registeredView = view
    }

    public func unregisterFromView() {
        guard let view = registeredView else {
            return
        }
        if let panGestureRecognizer = panGestureRecognizer {
            view.removeGestureRecognizer(panGestureRecognizer)
        }
        self.panGestureRecognizer = nil
        self.registeredView = nil
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
