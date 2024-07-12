import UIKit

class KTouchScreenInput {
    var eventQueue: KQueue<KEvent>

    var panInput: KPanInput
    var tapInput: KTapInput

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue
        self.panInput = KPanInput(eventQueue: eventQueue)
        self.tapInput = KTapInput(eventQueue: eventQueue)
    }

    public func registerWithView(view: UIView) {
        tapInput.registerWithView(view: view)
        panInput.registerWithView(view: view)
    }

}
