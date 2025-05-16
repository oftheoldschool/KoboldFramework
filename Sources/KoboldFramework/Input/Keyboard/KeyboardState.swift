import Foundation

public class KKeyboardState {
    private var pressedKeys: Set<KKeyboardKeyCode> = []
    private var heldKeys: Set<KKeyboardKeyCode> = []
    private var releasedKeys: Set<KKeyboardKeyCode> = []

    public func isKeyPressed(_ keyCode: KKeyboardKeyCode) -> Bool {
        return pressedKeys.contains(keyCode)
    }

    public func isKeyHeld(_ keyCode: KKeyboardKeyCode) -> Bool {
        return heldKeys.contains(keyCode)
    }

    public func isKeyPressedOrHeld(_ keyCode: KKeyboardKeyCode) -> Bool {
        return isKeyPressed(keyCode) || isKeyHeld(keyCode)
    }

    public func isKeyReleased(_ keyCode: KKeyboardKeyCode) -> Bool {
        return releasedKeys.contains(keyCode)
    }

    public func keyDown(_ keyCode: KKeyboardKeyCode) {
        pressedKeys.insert(keyCode)
    }
    
    public func keyUp(_ keyCode: KKeyboardKeyCode) {
        heldKeys.remove(keyCode)
        pressedKeys.remove(keyCode)
        releasedKeys.insert(keyCode)
    }

    func progressExistingStates() {
        if !pressedKeys.isEmpty {
            heldKeys = heldKeys.union(pressedKeys)
        }
        pressedKeys.removeAll()
        releasedKeys.removeAll()
    }

    func processInputs(events: [KEvent]) {
        progressExistingStates()

        for event in events {
            switch event {
            case .input(let input):
                switch input {
                case .keyboard(let keyboardEvent):
                    switch keyboardEvent {
                    case .keyDown(let keyDownEvent):
                        keyDown(keyDownEvent.keyCode)
                    case .keyUp(let keyUpEvent):
                        keyUp(keyUpEvent.keyCode)
                    }
                default:
                    continue
                }
            default: continue
            }
        }
    }
}
