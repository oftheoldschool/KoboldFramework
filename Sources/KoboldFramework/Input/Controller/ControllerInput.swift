import GameController
import KoboldLogging

public class KControllerInput: ObservableObject {
    private var virtualController: GCVirtualController?
    @Published
    public var allControllers: [KController] = []
    @Published
    public var activeController: KController?

    private let eventQueue: KQueue<KEvent>

    private var controllerObservers: [Any] = []
    private var currentHandlers: [Any] = []

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue
        self.virtualController = nil

        kinfo("Adding controllers")
        addConnectedControllers()

        kinfo("Setting up controller monitoring")
        setupControllerMonitoring()
    }

    deinit {
        disableController()
    }

    private func deactivateController(controllerId: String) {
        kinfo("Deactivating controller \(controllerId)")
        if let controller = allControllers.first(where: { $0.id == controllerId }) {
            switch controller.rawController {
            case .virtual(_):
                disableVirtualControllerView()
            case .physical(let rawController):
                removeControllerHandlers(rawController)
            }
        } else {
            kerror("Received request to deactivate non existent controller: \(controllerId)")
        }
    }

    private func createVirtualController() {
        kinfo("Creating virtual controller")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let virtualControllerExists = allControllers.contains(where: { $0.isVirtual })
            if virtualControllerExists {
                kwarn("Virtual controller already exists")
            } else {
                kinfo("Virtual controller does not already exist, creating...")
                let configuration = GCVirtualController.Configuration()
                configuration.elements = [
                    GCInputLeftThumbstick,
                    GCInputRightThumbstick,
                    GCInputButtonA,
                    GCInputButtonB,
                    GCInputButtonX,
                    GCInputButtonY,
                ]
                let newVirtualController = GCVirtualController(configuration: configuration)
                newVirtualController.connect { error in
                    if let error = error {
                        kerror("Failed to connect virtual controller: \(error.localizedDescription)")
                        return
                    } else {
                        kinfo("Successfully connected virtual controller")
                    }
                }
                virtualController = newVirtualController
                kinfo("Adding virtual controller to all controllers")
                allControllers.append(KController(newVirtualController))

                kinfo("Sending connected event for virtual controller")
                let connectedEvent = KPeripheralConnectedEvent(
                    peripheralType: .virtualController,
                    identifier: newVirtualController.identifier)
                eventQueue.enqueue(
                    item: .peripheral(.connected(connectedEvent)))

                kinfo("Disabling virtual controller view")
                disableVirtualControllerView()
            }
        }
    }

    private func addConnectedControllers() {
        kinfo("Adding connected controllers")
        createVirtualController()

        GCController.startWirelessControllerDiscovery()
        GCController.controllers().forEach { connectedController in
            let controllerId = connectedController.identifier
            kinfo("Found connected controller: \(controllerId)")
            if connectedController.name == "Apple Touch Controller" {
                kerror("Unexpectedly found connected Apple Touch Controller")
            } else if allControllers.contains(where: { $0.id == controllerId }) {
                kerror("Unexpectedly already added controller \(controllerId)")
            } else {
                kinfo("Adding connected controller \(controllerId) and sending notification")
                allControllers.append(KController(connectedController))

                let connectedEvent = KPeripheralConnectedEvent(
                    peripheralType: .physicalController,
                    identifier: connectedController.identifier)
                eventQueue.enqueue(item: .peripheral(.connected(connectedEvent)))
            }
        }
    }

    private func setupControllerMonitoring() {
        let connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self = self,
                let connectedController = notification.object as? GCController
            else {
                kwarn("Unable to convert connected controller notification object to GCController")
                return
            }

            let controllerId = connectedController.identifier
            if connectedController.name == "Apple Touch Controller" {
                kinfo("Received notification to connect Apple Touch Controller. Disabling view")
                disableVirtualControllerView()
            } else if allControllers.contains(where: { $0.id == controllerId }) {
                kerror("Received connect notification for already connected controller: \(controllerId)")
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else {
                        return
                    }
                    kinfo("Adding discovered controller \(controllerId) and sending event")
                    self.allControllers.append(KController(connectedController))

                    let connectedEvent = KPeripheralConnectedEvent(
                        peripheralType: .physicalController,
                        identifier: connectedController.identifier)
                    self.eventQueue.enqueue(item: .peripheral(.connected(connectedEvent)))
                }
            }
        }

        let disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self = self,
                let disconnectedController = notification.object as? GCController
            else {
                kwarn("Unable to convert disconnected controller notification object to GCController")
                return
            }

            let controllerId = disconnectedController.identifier
            if disconnectedController.name == "Apple Touch Controller" {
                kerror("Received notification to disconnect Apple Touch Controller disconnected")
            } else if allControllers.contains(where: { $0.id == controllerId }) {
                kinfo("Disconnecting controller \(controllerId) and sending event")
                deactivateController(controllerId: controllerId)
                self.allControllers.removeAll(where: { $0.id == controllerId} )

                let disconnectedEvent = KPeripheralDisconnectedEvent(
                    peripheralType: .physicalController,
                    identifier: disconnectedController.identifier)
                eventQueue.enqueue(
                    item: .peripheral(.disconnected(disconnectedEvent)))
            } else {
                kerror("Received notification to disconnect unknown controller: \(controllerId)")
            }
        }

        controllerObservers.append(connectObserver)
        controllerObservers.append(disconnectObserver)
    }

    private func activatePhysicalController(_ controller: KController) {
        kinfo("Setting up controller handlers for \(controller.id)")
        setupControllerHandlers(controller)

        kinfo("Setting active controller id to \(controller.id)")
        self.activeController = controller

        if controller.isVirtual {
            enableVirtualControllerView()
        }
    }

    public func enableDefaultController() {
        if let defaultController = allControllers.sorted(by: { (a, b) in !a.isVirtual && b.isVirtual }).first {
            enableControllerById(defaultController.id)
        }
    }

    public func enableControllerById(_ controllerId: String) {
        kinfo("Enabling controller \(controllerId)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let controller = allControllers.first(where: { $0.id == controllerId }) else {
                kerror("Unable to activate controller \(controllerId) - controller not found")
                return
            }

            if let activeController = activeController,
                let activeGCController = activeController.gcController
            {
                kinfo("Found existing controller: \(activeController.id), disabling it")
                self.removeControllerHandlers(activeGCController)
                self.deactivateController(controllerId: activeController.id)
            }

            kinfo("Activating controller \(controllerId)")
            self.activatePhysicalController(controller)
        }
        self.objectWillChange.send()
    }

    public func disableController() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let activeController = self.activeController {
                self.deactivateController(controllerId: activeController.id)
            }
        }
        self.objectWillChange.send()
    }

    private func setupControllerHandlers(_ controller: KController) {
        guard
            let gcController = controller.gcController,
            let gamepad = gcController.extendedGamepad
        else {
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

    private func enableVirtualControllerView() {
        kinfo("Enabling Virtual Controller View")
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                func enableControllerView(from view: UIView) {
                    if String(describing: type(of: view)) == "GCControllerView" {
                        kinfo("Enabling GCView")
                        view.isUserInteractionEnabled = true
                        view.alpha = 1
                        return
                    }
                    for subview in view.subviews {
                        enableControllerView(from: subview)
                    }
                }
                enableControllerView(from: window)
            }
        }
    }

    private func disableVirtualControllerView() {
        kinfo("Disabling Virtual Controller View")
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                func removeControllerView(from view: UIView) {
                    if String(describing: type(of: view)) == "GCControllerView" {
                        kinfo("Hiding GCView")
                        view.isUserInteractionEnabled = false
                        view.alpha = 0
                        return
                    }
                    for subview in view.subviews {
                        removeControllerView(from: subview)
                    }
                }
                removeControllerView(from: window)
            }
        }
    }
}
