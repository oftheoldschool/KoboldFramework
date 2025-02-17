import UIKit
import MetalKit.MTKView

public class KTouchScreenInput {
    private var eventQueue: KQueue<KEvent>

    public var panInput: KPanInput
    public var tapInput: KTapInput

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue
        self.panInput = KPanInput(eventQueue: eventQueue)
        self.tapInput = KTapInput(eventQueue: eventQueue)
    }

    public func enableTouchInput() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let view = windowScene.windows.first
        {
            func findMtkView(from view: UIView) -> UIView? {
                if view is MTKView {
                    return view
                }
                for subview in view.subviews {
                    return findMtkView(from: subview)
                }
                return nil
            }
            if let targetView = findMtkView(from: view) {
                tapInput.registerWithView(view: targetView)
                panInput.registerWithView(view: targetView)
            }
        }
    }

    public func disableTouchInput() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let view = windowScene.windows.first {
            func findMtkView(from view: UIView) -> UIView? {
                if view is MTKView {
                    return view
                }
                for subview in view.subviews {
                    return findMtkView(from: subview)
                }
                return nil
            }
            if let targetView = findMtkView(from: view) {
                targetView.gestureRecognizers?.forEach { recognizer in
                    recognizer.removeTarget(self, action: nil)
                    recognizer.isEnabled = false
                    targetView.removeGestureRecognizer(recognizer)
                }
            }
        }
    }
}
