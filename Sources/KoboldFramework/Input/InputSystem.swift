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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.inputMode == .controller {
                controllerInput.disableController()
            } else if self.inputMode == .touchscreen {
                touchScreenInput.disableTouchInput()
            }

            if inputMode == .controller {
                controllerInput.enableDefaultController()
            } else if inputMode == .touchscreen {
                touchScreenInput.enableTouchInput()
            }
            self.inputMode = inputMode
        }
        self.objectWillChange.send()
    }
}
