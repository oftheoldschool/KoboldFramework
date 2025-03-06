import SwiftUI

public enum KInputMode {
    case controller
    case touchscreen
    case hybrid
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
            let previousInputMode = self.inputMode

            switch previousInputMode {
            case .controller:
                controllerInput.disableController()
            case .touchscreen:
                touchScreenInput.disableTouchInput()
            case .hybrid:
                controllerInput.disableController()
                touchScreenInput.disableTouchInput()
            case .none:
                break
            }

            switch inputMode {
            case .controller:
                controllerInput.enableDefaultController()
            case .touchscreen:
                touchScreenInput.enableTouchInput()
            case .hybrid:
                touchScreenInput.enableTouchInput()
                controllerInput.enableDefaultController()
            case .none:
                break
            }
            self.inputMode = inputMode
        }
        self.objectWillChange.send()
    }
}
