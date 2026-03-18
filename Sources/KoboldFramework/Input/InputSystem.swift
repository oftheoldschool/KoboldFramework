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
    public static let mouse = KInputMode(rawValue: 1 << 3)
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

    @Published
    public var mouseInput: KMouseInput
    public var mouseState: KMouseState!

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

        self.mouseInput = KMouseInput(eventQueue: eventQueue)
        self.mouseState = KMouseState()
    }

    public func resetAllStates() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.resetAllStates()
            }
            return
        }
        controllerState.reset()
        touchScreenState.reset()
        keyboardState.reset()
        mouseState.reset()
    }

    public func processInputs(events: [KEvent]) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.processInputs(events: events)
            }
            return
        }

        var nextInputMode = inputMode

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
                    if peripheralDisconnectedEvent.peripheralType == .physicalController {
                        controllerState.reset()
                    }

                    if peripheralDisconnectedEvent.peripheralType == .physicalController && autoSwitchToVirtualOnDisconnect
                        && controllerInput.allControllers.count == 1
                        && nextInputMode.contains(.controller)
                    {
                        controllerInput.enableDefaultController()
                    }

                    if peripheralDisconnectedEvent.peripheralType == .keyboard {
                        keyboardState.reset()
                        if keyboardInput.connectedKeyboards.isEmpty {
                            nextInputMode.remove(.keyboard)
                        }
                    }

                    if peripheralDisconnectedEvent.peripheralType == .mouse {
                        mouseState.reset()
                        if mouseInput.connectedMice.isEmpty {
                            nextInputMode.remove(.mouse)
                        }
                    }
                }
            default: continue
            }
        }

        if nextInputMode != inputMode {
            applyInputMode(nextInputMode)
        }
    }

    public func toggleInputMode(_ inputMode: KInputMode) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.toggleInputMode(inputMode)
            }
            return
        }
        let newInputMode = self.inputMode.symmetricDifference(inputMode)
        applyInputMode(newInputMode)
    }

    public func setInputMode(_ inputMode: KInputMode) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.setInputMode(inputMode)
            }
            return
        }
        applyInputMode(inputMode)
    }

    public func setMousePointerMode(_ mode: KMousePointerMode) {
        mouseInput.setPointerMode(mode)
    }

    private func applyInputMode(_ inputMode: KInputMode) {
        let previousInputMode = self.inputMode
        if previousInputMode == inputMode {
            return
        }

        if previousInputMode.contains(.controller) {
            controllerInput.disableController()
        }
        if previousInputMode.contains(.touchscreen) {
            touchScreenInput.disableTouchInput()
        }
        if previousInputMode.contains(.keyboard) {
            keyboardInput.disableKeyboardInput()
        }
        if previousInputMode.contains(.mouse) {
            mouseInput.disableMouseInput()
        }

        if inputMode.contains(.controller) {
            controllerInput.enableDefaultController()
        } else {
            controllerState.reset()
        }
        if inputMode.contains(.touchscreen) {
            touchScreenInput.enableTouchInput()
        } else {
            touchScreenState.reset()
        }
        if inputMode.contains(.keyboard) {
            keyboardInput.enableKeyboardInput()
        } else {
            keyboardState.reset()
        }
        if inputMode.contains(.mouse) {
            mouseInput.enableMouseInput()
        } else {
            mouseState.reset()
        }

        self.inputMode = inputMode
    }
}
