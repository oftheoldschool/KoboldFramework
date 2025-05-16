import SwiftUI
import Combine
import UIKit
import GameController
import KoboldLogging

public class KKeyboardInput: ObservableObject {
    private var eventQueue: KQueue<KEvent>
    private var keyboardObservers: [Any] = []

    @Published
    public var connectedKeyboards: [GCKeyboard] = []

    @Published
    public var activeKeyboard: GCKeyboard?

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue

        kinfo("Setting up keyboard monitoring")
        setupKeyboardMonitoring()

        kinfo("Adding connected keyboards")
        addConnectedKeyboards()
    }

    deinit {
        disableKeyboardInput()
    }

    private func addConnectedKeyboards() {
        if let keyboard = GCKeyboard.coalesced {
            kinfo("Found connected keyboard")
            connectedKeyboards.append(keyboard)

            let connectedEvent = KPeripheralConnectedEvent(
                peripheralType: .keyboard,
                identifier: "hardware_keyboard")
            eventQueue.enqueue(item: .peripheral(.connected(connectedEvent)))
        }
    }

    private func setupKeyboardMonitoring() {
        let connectObserver = NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self = self,
                let connectedKeyboard = notification.object as? GCKeyboard
            else {
                kwarn("Unable to convert connected keyboard notification object to GCKeyboard")
                return
            }

            if !self.connectedKeyboards.contains(where: { $0.description == connectedKeyboard.description }) {
                kinfo("Adding discovered keyboard and sending event")
                self.connectedKeyboards.append(connectedKeyboard)

                let connectedEvent = KPeripheralConnectedEvent(
                    peripheralType: .keyboard,
                    identifier: connectedKeyboard.description)
                self.eventQueue.enqueue(item: .peripheral(.connected(connectedEvent)))
            } else {
                kerror("Received connect notification for already connected keyboard")
            }
        }

        let disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self = self,
                let disconnectedKeyboard = notification.object as? GCKeyboard
            else {
                kwarn("Unable to convert disconnected keyboard notification object to GCKeyboard")
                return
            }

            if self.connectedKeyboards.contains(where: { $0.description == disconnectedKeyboard.description }) {
                kinfo("Disconnecting keyboard and sending event")
                if self.activeKeyboard?.description == disconnectedKeyboard.description {
                    self.removeKeyboardHandlers(disconnectedKeyboard)
                    self.activeKeyboard = nil
                }

                self.connectedKeyboards.removeAll(where: { $0.description == disconnectedKeyboard.description })

                let disconnectedEvent = KPeripheralDisconnectedEvent(
                    peripheralType: .keyboard,
                    identifier: "hardware_keyboard")
                self.eventQueue.enqueue(
                    item: .peripheral(.disconnected(disconnectedEvent)))
            } else {
                kerror("Received notification to disconnect unknown keyboard")
            }
        }

        keyboardObservers.append(connectObserver)
        keyboardObservers.append(disconnectObserver)
    }

    public func enableKeyboardInput() {
        kinfo("Enabling keyboard input")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let keyboard = GCKeyboard.coalesced {
                if !self.connectedKeyboards.contains(where: { $0.description == keyboard.description }) {
                    self.connectedKeyboards.append(keyboard)
                }

                self.setupKeyboardHandlers(keyboard)
                self.activeKeyboard = keyboard
            } else {
                kwarn("No keyboard available to enable")
            }
        }
        self.objectWillChange.send()
    }

    public func disableKeyboardInput() {
        kinfo("Disabling keyboard input")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let activeKeyboard = self.activeKeyboard {
                self.removeKeyboardHandlers(activeKeyboard)
                self.activeKeyboard = nil
            }
        }
        self.objectWillChange.send()
    }

    private func setupKeyboardHandlers(_ keyboard: GCKeyboard) {
        kinfo("Setting up keyboard handlers")
        guard let keyboardInput = keyboard.keyboardInput else {
            kerror("Keyboard input not available")
            return
        }

        keyboardInput.keyChangedHandler = { [weak self] keyboard, key, keyCode, pressed in
            guard let self = self else { return }

            let event: KEvent
            if pressed {
                event = .input(.keyboard(.keyDown(KKeyboardEventKey(keyCode: KKeyboardKeyCode.fromGCKeyCode(keyCode)))))
            } else {
                event = .input(.keyboard(.keyUp(KKeyboardEventKey(keyCode: KKeyboardKeyCode.fromGCKeyCode(keyCode)))))
            }
            self.eventQueue.enqueue(item: event)
        }
    }

    private func removeKeyboardHandlers(_ keyboard: GCKeyboard) {
        kinfo("Removing keyboard handlers")
        keyboard.keyboardInput?.keyChangedHandler = nil
    }
}
