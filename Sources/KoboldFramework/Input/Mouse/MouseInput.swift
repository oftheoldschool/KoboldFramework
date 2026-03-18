import SwiftUI
import Combine
import UIKit
import GameController
import KoboldLogging
import MetalKit.MTKView

public enum KMousePointerMode {
    case passthrough
    case captured
}

public class KMouseInput: ObservableObject {
    private var eventQueue: KQueue<KEvent>
    private var mouseObservers: [Any] = []

    @Published
    public var connectedMice: [GCMouse] = []

    @Published
    public var activeMice: [GCMouse] = []
    private var inputEnabled = false
    @Published
    public private(set) var pointerMode: KMousePointerMode = .passthrough
    @Published
    public private(set) var isPointerCaptured: Bool = false
    private weak var pointerTrackingWindow: UIWindow?
    private weak var pointerTargetView: UIView?
    private var pointerHoverGestureRecognizer: UIHoverGestureRecognizer?
    private var lastPointerLocationInTrackingWindow: CGPoint?
    private var isPointerInsideTargetView = false
    private var pressedButtons: Set<KMouseButton> = []
    private var lastButtonDownTime: [KMouseButton: CFTimeInterval] = [:]
    private var lastButtonClickCount: [KMouseButton: Int] = [:]
    private let doubleClickThreshold: CFTimeInterval = 0.35

    var isEnabled: Bool {
        true
    }

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue

        if isEnabled {
            kinfo("Adding connected mice")
            addConnectedMice()

            kinfo("Setting up mouse monitoring")
            setupMouseMonitoring()
        }
    }

    deinit {
        disableMouseInput()
        mouseObservers.forEach { NotificationCenter.default.removeObserver($0) }
        mouseObservers.removeAll()
    }

    public func setPointerMode(_ mode: KMousePointerMode) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.setPointerMode(mode)
            }
            return
        }

        guard pointerMode != mode else {
            return
        }

        pointerMode = mode
        updatePointerCaptureState()
        if inputEnabled {
            setupPointerTracking()
        } else {
            teardownPointerTracking()
        }
    }

    private func updatePointerCaptureState() {
        if pointerMode == .captured && inputEnabled && !activeMice.isEmpty {
            capturePointerIfNeeded()
        } else {
            releasePointerCaptureIfNeeded()
        }
    }

    private func capturePointerIfNeeded() {
        guard !isPointerCaptured else {
            return
        }
        isPointerCaptured = true
#if os(macOS) || targetEnvironment(macCatalyst)
        NSCursor.hide()
        CGWarpMouseCursorPosition(
            CGPoint(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height / 2))
#endif
    }

    private func releasePointerCaptureIfNeeded() {
        guard isPointerCaptured else {
            return
        }
        isPointerCaptured = false
#if os(macOS) || targetEnvironment(macCatalyst)
        NSCursor.unhide()
#endif
    }

    private func addConnectedMice() {
        if let mouse = GCMouse.current {
            if !connectedMice.contains(where: { $0.identifier == mouse.identifier }) {
                kinfo("Found connected mouse")
                connectedMice.append(mouse)
            }

            let connectedEvent = KPeripheralConnectedEvent(
                peripheralType: .mouse,
                identifier: mouse.identifier)
            eventQueue.enqueue(item: .peripheral(.connected(connectedEvent)))
        }
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

    private func setupPointerTracking() {
        guard pointerMode == .passthrough else {
            teardownPointerTracking()
            isPointerInsideTargetView = false
            return
        }

        guard let window = activeWindow() else {
            pointerTargetView = nil
            isPointerInsideTargetView = false
            return
        }

        let targetView = findMtkView(from: window)

        if pointerTrackingWindow !== window || pointerHoverGestureRecognizer == nil {
            teardownPointerTracking()
            let hoverGestureRecognizer = UIHoverGestureRecognizer(
                target: self,
                action: #selector(pointerHoverChanged(gesture:)))
            hoverGestureRecognizer.cancelsTouchesInView = false
            window.addGestureRecognizer(hoverGestureRecognizer)
            pointerTrackingWindow = window
            pointerHoverGestureRecognizer = hoverGestureRecognizer
        }

        pointerTargetView = targetView
        if let location = lastPointerLocationInTrackingWindow {
            updatePointerInsideTargetState(location: location, in: window)
        } else {
            isPointerInsideTargetView = false
        }
    }

    private func teardownPointerTracking() {
        if let hoverGestureRecognizer = pointerHoverGestureRecognizer {
            pointerTrackingWindow?.removeGestureRecognizer(hoverGestureRecognizer)
        }
        pointerHoverGestureRecognizer = nil
        pointerTrackingWindow = nil
        pointerTargetView = nil
        lastPointerLocationInTrackingWindow = nil
    }

    private func refreshPointerTrackingIfNeeded() {
        guard inputEnabled && pointerMode == .passthrough else {
            return
        }

        let currentWindow = activeWindow()
        if pointerTrackingWindow !== currentWindow {
            setupPointerTracking()
            return
        }

        if let window = currentWindow {
            let currentTargetView = findMtkView(from: window)
            if pointerTargetView !== currentTargetView {
                pointerTargetView = currentTargetView
            }

            if let location = lastPointerLocationInTrackingWindow {
                updatePointerInsideTargetState(location: location, in: window)
            } else {
                isPointerInsideTargetView = false
            }
        } else {
            pointerTargetView = nil
            isPointerInsideTargetView = false
        }
    }

    private func updatePointerInsideTargetState(location: CGPoint, in window: UIWindow) {
        guard let targetView = pointerTargetView else {
            isPointerInsideTargetView = false
            return
        }
        guard let hitView = window.hitTest(location, with: nil) else {
            isPointerInsideTargetView = false
            return
        }

        var currentView: UIView? = hitView
        while let view = currentView {
            if view === targetView {
                isPointerInsideTargetView = true
                return
            }
            currentView = view.superview
        }
        isPointerInsideTargetView = false
    }

    private func isPointOverRenderView(_ point: CGPoint, in window: UIWindow) -> Bool {
        guard let targetView = findMtkView(from: window) else {
            return false
        }
        guard let hitView = window.hitTest(point, with: nil) else {
            return false
        }

        var currentView: UIView? = hitView
        while let view = currentView {
            if view === targetView {
                return true
            }
            currentView = view.superview
        }
        return false
    }

    private func shouldDispatchCapturedEvent() -> Bool {
        guard let window = activeWindow() else {
            return false
        }
        let centerPoint = CGPoint(
            x: window.bounds.midX,
            y: window.bounds.midY)
        return isPointOverRenderView(centerPoint, in: window)
    }

    @objc
    private func pointerHoverChanged(gesture: UIHoverGestureRecognizer) {
        guard let trackingWindow = pointerTrackingWindow else {
            return
        }

        switch gesture.state {
        case .began, .changed:
            let location = gesture.location(in: trackingWindow)
            lastPointerLocationInTrackingWindow = location
            updatePointerInsideTargetState(location: location, in: trackingWindow)
        case .ended, .cancelled, .failed:
            lastPointerLocationInTrackingWindow = nil
            isPointerInsideTargetView = false
        default:
            break
        }
    }

    private func shouldDispatchMoveOrScrollEvent() -> Bool {
        refreshPointerTrackingIfNeeded()
        if pointerMode == .captured {
            return shouldDispatchCapturedEvent()
        }
        return isPointerInsideTargetView
    }

    private func shouldDispatchButtonEvent(button: KMouseButton, pressed: Bool) -> Bool {
        refreshPointerTrackingIfNeeded()
        if pointerMode == .captured {
            if pressed {
                return shouldDispatchCapturedEvent()
            }
            return pressedButtons.contains(button)
        }
        if pressed {
            return isPointerInsideTargetView
        }
        return pressedButtons.contains(button)
    }

    private func nextClickCount(for button: KMouseButton) -> Int {
        let now = CACurrentMediaTime()
        let clickCount: Int
        if let previous = lastButtonDownTime[button], (now - previous) <= doubleClickThreshold {
            clickCount = 2
        } else {
            clickCount = 1
        }
        lastButtonDownTime[button] = now
        lastButtonClickCount[button] = clickCount
        return clickCount
    }

    private func handleButtonChange(button: KMouseButton, pressed: Bool) {
        guard shouldDispatchButtonEvent(button: button, pressed: pressed) else {
            return
        }

        let clickCount: Int
        let event: KEvent
        if pressed {
            clickCount = nextClickCount(for: button)
            pressedButtons.insert(button)
            event = .input(.mouse(.buttonDown(KMouseEventButton(button: button, clickCount: clickCount))))
        } else {
            clickCount = lastButtonClickCount[button] ?? 1
            pressedButtons.remove(button)
            event = .input(.mouse(.buttonUp(KMouseEventButton(button: button, clickCount: clickCount))))
        }
        eventQueue.enqueue(item: event)
    }

    private func setupMouseMonitoring() {
        let connectObserver = NotificationCenter.default.addObserver(
            forName: .GCMouseDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self = self,
                let connectedMouse = notification.object as? GCMouse
            else {
                kwarn("Unable to convert connected mouse notification object to GCMouse")
                return
            }

            if !self.connectedMice.contains(where: { $0.identifier == connectedMouse.identifier }) {
                kinfo("Adding discovered mouse \(connectedMouse.identifier) and sending event")
                self.connectedMice.append(connectedMouse)
                if self.inputEnabled {
                    self.setupMouseHandlers(connectedMouse)
                    self.activeMice.append(connectedMouse)
                    self.updatePointerCaptureState()
                }

                let connectedEvent = KPeripheralConnectedEvent(
                    peripheralType: .mouse,
                    identifier: connectedMouse.identifier)
                self.eventQueue.enqueue(item: .peripheral(.connected(connectedEvent)))
            } else {
                kerror("Received connect notification for already connected mouse")
            }
        }

        let disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCMouseDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self = self,
                let disconnectedMouse = notification.object as? GCMouse
            else {
                kwarn("Unable to convert disconnected mouse notification object to GCMouse")
                return
            }

            if self.connectedMice.contains(where: { $0.identifier == disconnectedMouse.identifier }) {
                kinfo("Disconnecting mouse and sending event")

                if self.activeMice.contains(where: { activeMouse in
                    activeMouse.identifier == disconnectedMouse.identifier
                }) {
                    self.removeMouseHandlers(disconnectedMouse)
                }
                self.activeMice.removeAll(where: { activeMouse in
                    activeMouse.identifier == disconnectedMouse.identifier
                })
                self.connectedMice.removeAll(where: { activeMouse in
                    activeMouse.identifier == disconnectedMouse.identifier
                })
                self.updatePointerCaptureState()

                let disconnectedEvent = KPeripheralDisconnectedEvent(
                    peripheralType: .mouse,
                    identifier: disconnectedMouse.identifier)
                self.eventQueue.enqueue(
                    item: .peripheral(.disconnected(disconnectedEvent)))
            } else {
                kerror("Received notification to disconnect unknown mouse")
            }
        }

        mouseObservers.append(connectObserver)
        mouseObservers.append(disconnectObserver)
    }

    public func enableMouseInput() {
        kinfo("Enabling mouse input")
        if !isEnabled {
            return
        }
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.enableMouseInput()
            }
            return
        }

        inputEnabled = true
        addConnectedMice()
        if connectedMice.isEmpty {
            kwarn("No mouse available to enable")
        } else {
            connectedMice.forEach { mouse in
                self.setupMouseHandlers(mouse)
                if !self.activeMice.contains(where: { $0.identifier == mouse.identifier }) {
                    self.activeMice.append(mouse)
                }
            }
        }
        setupPointerTracking()
        updatePointerCaptureState()
    }

    public func disableMouseInput() {
        kinfo("Disabling mouse input")
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.disableMouseInput()
            }
            return
        }
        inputEnabled = false

        activeMice.forEach { activeMouse in
            self.removeMouseHandlers(activeMouse)
        }
        activeMice.removeAll()
        pressedButtons.removeAll()
        lastButtonDownTime.removeAll()
        lastButtonClickCount.removeAll()
        teardownPointerTracking()
        isPointerInsideTargetView = false
        releasePointerCaptureIfNeeded()
    }

    private func setupMouseHandlers(_ mouse: GCMouse) {
        kinfo("Setting up mouse handlers")
        mouse.handlerQueue = DispatchQueue.main

        mouse.mouseInput?.mouseMovedHandler = { [weak self] mouse, deltaX, deltaY in
            guard let self = self else { return }
            if self.isPointerCaptured {
#if os(macOS) || targetEnvironment(macCatalyst)
                CGWarpMouseCursorPosition(
                    CGPoint(
                        x: UIScreen.main.bounds.width / 2,
                        y: UIScreen.main.bounds.height / 2))
#endif
            }
            guard self.shouldDispatchMoveOrScrollEvent() else { return }

            let event: KEvent = .input(.mouse(.move(KMouseEventMove(
                deltaX: deltaX,
                deltaY: deltaY,
                position: nil
            ))))
            self.eventQueue.enqueue(item: event)
        }

        if let leftButton = mouse.mouseInput?.leftButton {
            leftButton.pressedChangedHandler = { [weak self] button, value, pressed in
                guard let self = self else { return }
                self.handleButtonChange(button: .left, pressed: pressed)
            }
        }

        if let rightButton = mouse.mouseInput?.rightButton {
            rightButton.pressedChangedHandler = { [weak self] button, value, pressed in
                guard let self = self else { return }
                self.handleButtonChange(button: .right, pressed: pressed)
            }
        }

        for button in mouse.mouseInput?.auxiliaryButtons ?? [] {
            button.pressedChangedHandler = { [weak self] button, value, pressed in
                guard let self = self else { return }

                let mouseButton = KMouseButton.fromGCMouseInput(button)
                self.handleButtonChange(button: mouseButton, pressed: pressed)
            }
        }
    }

    private func removeMouseHandlers(_ mouse: GCMouse) {
        kinfo("Removing mouse handlers")

        mouse.mouseInput?.mouseMovedHandler = nil
        mouse.mouseInput?.leftButton.pressedChangedHandler = nil
        mouse.mouseInput?.rightButton?.pressedChangedHandler = nil

        for button in mouse.mouseInput?.auxiliaryButtons ?? [] {
            button.pressedChangedHandler = nil
        }
    }
}
