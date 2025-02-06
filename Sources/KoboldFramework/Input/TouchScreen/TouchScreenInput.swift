import UIKit

public class KTouchScreenInput {
    private var eventQueue: KQueue<KEvent>

    public var panInput: KPanInput
    public var tapInput: KTapInput

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
