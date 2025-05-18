import SwiftUI
import Combine
import UIKit
import GameController
import KoboldLogging

public class KMouseInput: ObservableObject {
    private var eventQueue: KQueue<KEvent>
    private var mouseObservers: [Any] = []

    @Published
    public var connectedMice: [GCMouse] = []

    @Published
    public var activeMice: [GCMouse] = []

    var isEnabled: Bool {
#if os(macOS) || targetEnvironment(macCatalyst)
        true
#else
        false
#endif
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
    }

    private func addConnectedMice() {
        if let mouse = GCMouse.current {
            kinfo("Found connected mouse")
            connectedMice.append(mouse)

            let connectedEvent = KPeripheralConnectedEvent(
                peripheralType: .mouse,
                identifier: mouse.identifier)
            eventQueue.enqueue(item: .peripheral(.connected(connectedEvent)))
        }
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
                self.activeMice.append(connectedMouse)

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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if connectedMice.isEmpty {
                kwarn("No mouse available to enable")
            } else {
                connectedMice.forEach { mouse in
                    print("found current mouse: \(mouse.identifier)")
                    self.setupMouseHandlers(mouse)
                    self.activeMice.append(mouse)

#if os(macOS) || targetEnvironment(macCatalyst)
                    NSCursor.hide()
                    CGWarpMouseCursorPosition(
                            CGPoint(
                                x: UIScreen.main.bounds.width / 2,
                                y: UIScreen.main.bounds.height / 2))
#endif
                }
            }
       }
        self.objectWillChange.send()
    }

    public func disableMouseInput() {
        kinfo("Disabling mouse input")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            activeMice.forEach { activeMouse in
                self.removeMouseHandlers(activeMouse)

#if os(macOS) || targetEnvironment(macCatalyst)
                NSCursor.unhide()
#endif
            }
            activeMice.removeAll()
        }
        self.objectWillChange.send()
    }

    private func setupMouseHandlers(_ mouse: GCMouse) {
        kinfo("Setting up mouse handlers")
        mouse.handlerQueue = DispatchQueue.global(qos: .userInteractive)

        mouse.mouseInput?.mouseMovedHandler = { [weak self] mouse, deltaX, deltaY in
            guard let self = self else { return }
#if os(macOS) || targetEnvironment(macCatalyst)
            CGWarpMouseCursorPosition(
                CGPoint(
                    x: UIScreen.main.bounds.width / 2,
                    y: UIScreen.main.bounds.height / 2))
#endif

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

                let event: KEvent
                if pressed {
                    event = .input(.mouse(.buttonDown(KMouseEventButton(button: .left))))
                } else {
                    event = .input(.mouse(.buttonUp(KMouseEventButton(button: .left))))
                }
                self.eventQueue.enqueue(item: event)
            }
        }

        if let rightButton = mouse.mouseInput?.rightButton {
            rightButton.pressedChangedHandler = { [weak self] button, value, pressed in
                guard let self = self else { return }

                let event: KEvent
                if pressed {
                    event = .input(.mouse(.buttonDown(KMouseEventButton(button: .right))))
                } else {
                    event = .input(.mouse(.buttonUp(KMouseEventButton(button: .right))))
                }
                self.eventQueue.enqueue(item: event)
            }
        }

        for button in mouse.mouseInput?.auxiliaryButtons ?? [] {
            button.pressedChangedHandler = { [weak self] button, value, pressed in
                guard let self = self else { return }

                let mouseButton = KMouseButton.fromGCMouseInput(button)
                let event: KEvent
                if pressed {
                    event = .input(.mouse(.buttonDown(KMouseEventButton(button: mouseButton))))
                } else {
                    event = .input(.mouse(.buttonUp(KMouseEventButton(button: mouseButton))))
                }
                self.eventQueue.enqueue(item: event)
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
