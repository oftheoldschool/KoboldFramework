import UIKit
import MetalKit.MTKView

public class KTouchScreenInput {
    private var eventQueue: KQueue<KEvent>
    private var touchInputEnabled = false
    private var registerRetryWorkItem: DispatchWorkItem?
    private let registerRetryDelay: TimeInterval = 0.1
    private var remainingRegisterRetries = 0
    private let maxRegisterRetries = 20

    public var panInput: KPanInput
    public var tapInput: KTapInput

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue
        self.panInput = KPanInput(eventQueue: eventQueue)
        self.tapInput = KTapInput(eventQueue: eventQueue)
    }

    private func activeWindow() -> UIWindow? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let foregroundScenes = windowScenes.filter { $0.activationState == .foregroundActive }

        for scene in foregroundScenes {
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                return keyWindow
            }
        }
        for scene in foregroundScenes {
            if let firstWindow = scene.windows.first {
                return firstWindow
            }
        }

        for scene in windowScenes {
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                return keyWindow
            }
        }
        return windowScenes.first?.windows.first
    }

    private func findMtkView(from rootView: UIView) -> UIView? {
        if rootView is KMetalView {
            return rootView
        }
        for subview in rootView.subviews {
            if let target = findMtkView(from: subview) {
                return target
            }
        }
        return nil
    }

    public func enableTouchInput() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.enableTouchInput()
            }
            return
        }
        touchInputEnabled = true
        remainingRegisterRetries = maxRegisterRetries
        registerTouchRecognizersIfPossible()
    }

    public func disableTouchInput() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.disableTouchInput()
            }
            return
        }
        touchInputEnabled = false
        registerRetryWorkItem?.cancel()
        registerRetryWorkItem = nil
        tapInput.unregisterFromView()
        panInput.unregisterFromView()
    }

    private func registerTouchRecognizersIfPossible() {
        guard touchInputEnabled else {
            return
        }

        if let view = activeWindow(), let targetView = findMtkView(from: view) {
            tapInput.registerWithView(view: targetView)
            panInput.registerWithView(view: targetView)
            registerRetryWorkItem?.cancel()
            registerRetryWorkItem = nil
            return
        }

        guard remainingRegisterRetries > 0 else {
            return
        }

        remainingRegisterRetries -= 1
        registerRetryWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.registerTouchRecognizersIfPossible()
        }
        registerRetryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + registerRetryDelay, execute: workItem)
    }
}
