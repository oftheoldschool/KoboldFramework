import GameController
import KoboldLogging

public struct KControllerType: Hashable {
    public let id: String
    public let description: String
    public let isVirtual: Bool
}

public class KControllerInput: ObservableObject {
    @Published
    public var availableControllers: [KControllerType] = []
    @Published
    public var activeController: KControllerType?
    private var currentController: GCController?

    private let eventQueue: KQueue<KEvent>

    private var virtualController: GCVirtualController?
    private var physicalControllers: [String: GCController] = [:]

    private var controllerObservers: [Any] = []
    private var currentHandlers: [Any] = []

    private static let defaultController = KControllerType(
        id: "Apple Touch Controller",
        description: "Virtual Controller",
        isVirtual: true)

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue
        setupControllerMonitoring()

        GCController.startWirelessControllerDiscovery()
        GCController.controllers().forEach { controller in
            let controllerId = controller.vendorName ?? "Unknown Controller"
            physicalControllers[controllerId] = controller
            availableControllers.append(
                KControllerType(
                    id: controllerId,
                    description: controller.description,
                    isVirtual: false))
        }

        availableControllers.append(Self.defaultController)
    }

    deinit {
        disableController()
    }

    public func isControllerActive(_ type: KControllerType) -> Bool {
        activeController == type
    }

    public func enableDefaultController() {
        enableController(Self.defaultController)
    }

    public func enableController(_ type: KControllerType) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let currentController = self.currentController {
                self.removeControllerHandlers(currentController)
            }
            self.cleanupVirtualControllerView()
            self.deactivatePhysicalController()

            if type.id == "Apple Touch Controller" {
                let configuration = GCVirtualController.Configuration()
                configuration.elements = [
                    GCInputLeftThumbstick,
                    GCInputRightThumbstick,
                    GCInputButtonA,
                    GCInputButtonB,
                    GCInputButtonX,
                    GCInputButtonY,
                ]

                virtualController = GCVirtualController(configuration: configuration)
                virtualController?.connect { [weak self] error in
                    guard let self = self else { return }

                    if let error = error {
                        kerror("Failed to connect virtual controller: \(error.localizedDescription)")
                        return
                    }

                    if let controller = self.virtualController?.controller {
                        self.activatePhysicalController(controller, type: type)
                    }
                }
            } else if let controller = self.physicalControllers[type.id] {
                self.activatePhysicalController(controller, type: type)
            }
        }
        self.objectWillChange.send()
    }

    private func cleanupVirtualControllerView() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            func removeControllerView(from view: UIView) {
                if String(describing: type(of: view)) == "GCControllerView" {
                    view.removeFromSuperview()
                    return
                }
                for subview in view.subviews {
                    removeControllerView(from: subview)
                }
            }
            removeControllerView(from: window)
        }
    }

    public func disableController() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.deactivatePhysicalController()
        }
        self.objectWillChange.send()
    }

    private func setupControllerMonitoring() {
        let connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let controller = notification.object as? GCController
            else { return }

            let controllerId = controller.vendorName ?? "Unknown Controller"

            if controllerId != "Apple Touch Controller" {
                let type = KControllerType(
                    id: controllerId,
                    description: controllerId,
                    isVirtual: false)
                self.physicalControllers[controllerId] = controller
                if !self.availableControllers.contains(type) {
                    self.availableControllers.append(type)
                }
            }
        }

        let disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let controller = notification.object as? GCController
            else { return }

            let controllerId = controller.vendorName ?? controller.productCategory
            let type = KControllerType(
                id: controllerId,
                description: controllerId,
                isVirtual: controllerId == "Apple Touch Controller")

            if controllerId != "Apple Touch Controller" {
                self.physicalControllers.removeValue(forKey: controllerId)
                self.availableControllers.removeAll(where: { $0 == type })
            }

            if type == self.activeController {
                self.deactivatePhysicalController()
            }
        }

        controllerObservers.append(connectObserver)
        controllerObservers.append(disconnectObserver)
    }

    private func activatePhysicalController(_ controller: GCController, type: KControllerType) {
        currentController = controller
        activeController = type
        setupControllerHandlers(controller)

        let connectedEvent = KPeripheralConnectedEvent(peripheralType: .physicalController)
        eventQueue.enqueue(item: .peripheral(.connected(connectedEvent)))
    }

    private func deactivatePhysicalController() {
        if activeController != nil {
            if let controller = currentController,
               let controllerId = controller.vendorName
            {
                removeControllerHandlers(controller)
                if controllerId == "Apple Touch Controller" {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        func removeControllerView(from view: UIView) {
                            if String(describing: type(of: view)) == "GCControllerView" {
                                view.removeFromSuperview()
                                return
                            }
                            for subview in view.subviews {
                                removeControllerView(from: subview)
                            }
                        }
                        removeControllerView(from: window)
                    }
                    virtualController?.disconnect()
                    virtualController = nil
                }
            }

            activeController = nil
            currentController = nil

            let disconnectedEvent = KPeripheralDisconnectedEvent(peripheralType: .physicalController)
            eventQueue.enqueue(item: .peripheral(.disconnected(disconnectedEvent)))
        }
    }

    private func setupControllerHandlers(_ controller: GCController) {
        guard let gamepad = controller.extendedGamepad else {
            kerror("Extended gamepad not available")
            return
        }

        gamepad.buttonA.valueChangedHandler = { [weak self] button, value, pressed in
            let event = KEvent.input(.controller(.button(KControllerEventButton(
                button: .buttonA,
                state: pressed ? .pressed : .released
            ))))
            self?.eventQueue.enqueue(item: event)
        }

        gamepad.buttonB.valueChangedHandler = { [weak self] button, value, pressed in
            let event = KEvent.input(.controller(.button(KControllerEventButton(
                button: .buttonB,
                state: pressed ? .pressed : .released
            ))))
            self?.eventQueue.enqueue(item: event)
        }

        gamepad.buttonX.valueChangedHandler = { [weak self] button, value, pressed in
            let event = KEvent.input(.controller(.button(KControllerEventButton(
                button: .buttonX,
                state: pressed ? .pressed : .released
            ))))
            self?.eventQueue.enqueue(item: event)
        }

        gamepad.buttonY.valueChangedHandler = { [weak self] button, value, pressed in
            let event = KEvent.input(.controller(.button(KControllerEventButton(
                button: .buttonY,
                state: pressed ? .pressed : .released
            ))))
            self?.eventQueue.enqueue(item: event)
        }

        var leftStickActive = false
        var rightStickActive = false

        gamepad.leftThumbstick.valueChangedHandler = { [weak self] stick, xValue, yValue in
            guard let self = self else { return }

            let state: KControllerEventStickState
            if !leftStickActive && (xValue != 0 || yValue != 0) {
                state = .began
                leftStickActive = true
            } else if leftStickActive && xValue == 0 && yValue == 0 {
                state = .ended
                leftStickActive = false
            } else {
                state = .changed
            }

            let event = KEvent.input(.controller(.stick(KControllerEventStick(
                stick: .stickLeft,
                state: state,
                offset: (x: xValue, y: yValue)
            ))))
            self.eventQueue.enqueue(item: event)
        }

        gamepad.rightThumbstick.valueChangedHandler = { [weak self] stick, xValue, yValue in
            guard let self = self else { return }

            let state: KControllerEventStickState
            if !rightStickActive && (xValue != 0 || yValue != 0) {
                state = .began
                rightStickActive = true
            } else if rightStickActive && xValue == 0 && yValue == 0 {
                state = .ended
                rightStickActive = false
            } else {
                state = .changed
            }

            let event = KEvent.input(.controller(.stick(KControllerEventStick(
                stick: .stickRight,
                state: state,
                offset: (x: xValue, y: yValue)
            ))))
            self.eventQueue.enqueue(item: event)
        }
    }

    private func removeControllerHandlers(_ controller: GCController) {
        guard let gamepad = controller.extendedGamepad else { return }

        gamepad.buttonA.valueChangedHandler = nil
        gamepad.buttonB.valueChangedHandler = nil
        gamepad.buttonX.valueChangedHandler = nil
        gamepad.buttonY.valueChangedHandler = nil

        gamepad.leftThumbstick.valueChangedHandler = nil
        gamepad.rightThumbstick.valueChangedHandler = nil
    }
}
