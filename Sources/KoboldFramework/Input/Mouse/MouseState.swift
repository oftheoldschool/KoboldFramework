import Foundation
import CoreGraphics

public class KMouseState {
    private var pressedButtons: Set<KMouseButton> = []
    private var heldButtons: Set<KMouseButton> = []
    private var releasedButtons: Set<KMouseButton> = []
    
    public private(set) var position: CGPoint = .zero
    public private(set) var deltaPosition: CGPoint = .zero
    public private(set) var scrollDelta: CGPoint = .zero
    
    public func isButtonPressed(_ button: KMouseButton) -> Bool {
        return pressedButtons.contains(button)
    }
    
    public func isButtonHeld(_ button: KMouseButton) -> Bool {
        return heldButtons.contains(button)
    }
    
    public func isButtonPressedOrHeld(_ button: KMouseButton) -> Bool {
        return isButtonPressed(button) || isButtonHeld(button)
    }
    
    public func isButtonReleased(_ button: KMouseButton) -> Bool {
        return releasedButtons.contains(button)
    }
    
    public func buttonDown(_ button: KMouseButton) {
        pressedButtons.insert(button)
    }
    
    public func buttonUp(_ button: KMouseButton) {
        heldButtons.remove(button)
        pressedButtons.remove(button)
        releasedButtons.insert(button)
    }
    
    public func mouseMove(deltaX: Float, deltaY: Float, position: CGPoint?) {
        deltaPosition = CGPoint(x: CGFloat(deltaX), y: CGFloat(deltaY))
        if let position = position {
            self.position = position
        } else {
            self.position.x += deltaPosition.x
            self.position.y += deltaPosition.y
        }
    }
    
    public func mouseScroll(deltaX: Float, deltaY: Float) {
        scrollDelta = CGPoint(x: CGFloat(deltaX), y: CGFloat(deltaY))
    }
    
    func progressExistingStates() {
        if !pressedButtons.isEmpty {
            heldButtons = heldButtons.union(pressedButtons)
        }
        pressedButtons.removeAll()
        releasedButtons.removeAll()
        deltaPosition = .zero
        scrollDelta = .zero
    }
    
    func processInputs(events: [KEvent]) {
        progressExistingStates()
        
        for event in events {
            switch event {
            case .input(let input):
                switch input {
                case .mouse(let mouseEvent):
                    switch mouseEvent {
                    case .buttonDown(let buttonEvent):
                        buttonDown(buttonEvent.button)
                    case .buttonUp(let buttonEvent):
                        buttonUp(buttonEvent.button)
                    case .move(let moveEvent):
                        mouseMove(deltaX: moveEvent.deltaX, deltaY: moveEvent.deltaY, position: moveEvent.position)
                    case .scroll(let scrollEvent):
                        mouseScroll(deltaX: scrollEvent.deltaX, deltaY: scrollEvent.deltaY)
                    }
                default:
                    continue
                }
            default: continue
            }
        }
    }
}
