import SwiftUI
import KoboldLogging

public enum KInputMode {
    case controller
    case touchscreen
    case hybrid
    case none

    var hasControllerInput: Bool {
        return switch self {
        case .controller, .hybrid:
            true
        default:
            false
        }
    }
}

public class KInputSystem: ObservableObject {
    @Published
    public var inputMode: KInputMode

    public var touchScreenInput: KTouchScreenInput!
    public var touchScreenState: KTouchScreenState!

    @Published
    public var controllerInput: KControllerInput
    public var controllerState: KControllerState!

    public var autoSwitchToPhysicalOnConnect: Bool
    public var autoSwitchToVirtualOnDisconnect: Bool

    init(
        eventQueue: KQueue<KEvent>,
        autoSwitchToVirtualOnDisconnect: Bool = true,
        autoSwitchToPhysicalOnConnect: Bool = true
    ) {
        self.inputMode = .none
        self.autoSwitchToVirtualOnDisconnect = autoSwitchToVirtualOnDisconnect
        self.autoSwitchToPhysicalOnConnect = autoSwitchToPhysicalOnConnect

        self.touchScreenInput = KTouchScreenInput(eventQueue: eventQueue)
        self.touchScreenState = KTouchScreenState()

        self.controllerInput = KControllerInput(eventQueue: eventQueue)
        self.controllerState = KControllerState()
    }
    
    public func processInputs(events: [KEvent]) {
        for event in events {
            switch event {
            case .peripheral(let peripheral):
                switch peripheral {
                case .connected(let connectedEvent):
                    if autoSwitchToPhysicalOnConnect
                        && connectedEvent.peripheralType == .physicalController
                        && controllerInput.activeController?.isVirtual ?? false
                    {
                        controllerInput.enableControllerById(connectedEvent.identifier)
                    }
                case .disconnected(_):
                    if autoSwitchToVirtualOnDisconnect
                        && controllerInput.allControllers.count == 1
                        && inputMode.hasControllerInput
                    {
                        controllerInput.enableDefaultController()
                    }
                }
            default: continue
            }
        }
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
