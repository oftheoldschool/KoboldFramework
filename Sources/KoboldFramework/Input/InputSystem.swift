import SwiftUI
import KoboldLogging

public struct KInputMode: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none = KInputMode([])
    public static let controller = KInputMode(rawValue: 1 << 0)
    public static let touchscreen = KInputMode(rawValue: 1 << 1)
    public static let keyboard = KInputMode(rawValue: 1 << 2)
}

public class KInputSystem: ObservableObject {
    @Published
    public var inputMode: KInputMode

    public var touchScreenInput: KTouchScreenInput
    public var touchScreenState: KTouchScreenState!

    @Published
    public var controllerInput: KControllerInput
    public var controllerState: KControllerState!

    @Published
    public var keyboardInput: KKeyboardInput
    public var keyboardState: KKeyboardState!

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

        self.keyboardInput = KKeyboardInput(eventQueue: eventQueue)
        self.keyboardState = KKeyboardState()
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
                case .disconnected(let peripheralDisconnectedEvent):
                    if peripheralDisconnectedEvent.peripheralType == .physicalController && autoSwitchToVirtualOnDisconnect
                        && controllerInput.allControllers.count == 1
                        && inputMode.contains(.controller)
                    {
                        controllerInput.enableDefaultController()
                    }

                    if peripheralDisconnectedEvent.peripheralType == .keyboard {
                        if keyboardInput.connectedKeyboards.isEmpty {
                            inputMode.remove(.keyboard)
                        }
                    }
                }
            default: continue
            }
        }
    }

    public func toggleInputMode(_ inputMode: KInputMode) {
        let newInputMode = self.inputMode.symmetricDifference(inputMode)
        setInputMode(newInputMode)
    }

    public func setInputMode(_ inputMode: KInputMode) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let previousInputMode = self.inputMode

            if previousInputMode.contains(.controller) {
                controllerInput.disableController()
            }
            if previousInputMode.contains(.touchscreen) {
                touchScreenInput.disableTouchInput()
            }
            if previousInputMode.contains(.keyboard) {
                keyboardInput.disableKeyboardInput()
            }

            if inputMode.contains(.controller) {
                controllerInput.enableDefaultController()
            }
            if inputMode.contains(.touchscreen) {
                touchScreenInput.enableTouchInput()
            }
            if inputMode.contains(.keyboard) {
                keyboardInput.enableKeyboardInput()
            }

            self.inputMode = inputMode
        }
        self.objectWillChange.send()
    }
}
