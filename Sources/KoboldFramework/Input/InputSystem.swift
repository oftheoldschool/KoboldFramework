import SwiftUI

public enum KInputMode {
    case controller
    case touchscreen
    case none
}

public class KInputSystem: ObservableObject {
    @Published
    public var inputMode: KInputMode

    public var touchScreenInput: KTouchScreenInput!
    public var touchScreenState: KTouchScreenState!

    @Published
    public var controllerInput: KControllerInput
    public var controllerState: KControllerState!

    init(_ eventQueue: KQueue<KEvent>) {
        self.inputMode = .none

        self.touchScreenInput = KTouchScreenInput(eventQueue: eventQueue)
        self.touchScreenState = KTouchScreenState()

        self.controllerInput = KControllerInput(eventQueue: eventQueue)
        self.controllerState = KControllerState()
    }

    public func getAvailableControllers() -> [KControllerType] {
        return controllerInput.availableControllers
    }

    public func setInputMode(_ inputMode: KInputMode) {
        if self.inputMode == .controller {
            controllerInput.disableController()
            touchScreenInput.enableTouchInput()
        }
        if inputMode == .controller {
            touchScreenInput.disableTouchInput()
            controllerInput.enableDefaultController()
        }
        self.inputMode = inputMode
        self.objectWillChange.send()
    }
}
