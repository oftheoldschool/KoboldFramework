import Foundation
import GameController
import KoboldLogging

public class KControllerInput: ObservableObject {
    private var virtualController: GCVirtualController?
    @Published
    public var allControllers: [KController] = []
    @Published
    public var activeController: KController?

    public var virtualControllerFadeTime: TimeInterval = 0
    private var virtualControllerConnectAttempts: Int = 0
    private let maxVirtualControllerConnectAttempts: Int = 6

    /// When false, the on-screen virtual controller is not created/connected (so it
    /// never appears) and is never auto-selected as the default controller. A
    /// physical controller can still be activated normally. Defaults to false on a
    /// Mac Catalyst / "iPad app on Mac", where a keyboard/mouse is expected.
    /// Toggle at runtime via `KInputSystem.setVirtualControllerAllowed`.
    public var allowVirtualController: Bool = false

    /// A real (non-virtual) controller is connected.
    public var hasPhysicalController: Bool {
        allControllers.contains { !$0.isVirtual }
    }

    /// The on-screen virtual controller is the currently-active controller.
    public var isVirtualControllerActive: Bool {
        activeController?.isVirtual ?? false
    }

    private let eventQueue: KQueue<KEvent>

    private var controllerObservers: [Any] = []

    init(eventQueue: KQueue<KEvent>) {
        self.eventQueue = eventQueue
        self.virtualController = nil

        kinfo("Controller input runtime: isMacCatalystApp=\(ProcessInfo.processInfo.isMacCatalystApp), allowVirtualController=\(allowVirtualController)")
        kinfo("Adding controllers")
        addConnectedControllers()

        kinfo("Setting up controller monitoring")
        setupControllerMonitoring()
    }

    deinit {
        disableController()
        controllerObservers.forEach { NotificationCenter.default.removeObserver($0) }
        controllerObservers.removeAll()
    }

    private func activeWindow() -> UIWindow? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let foregroundScenes = windowScenes.filter { $0.activationState == .foregroundActive }

        for scene in foregroundScenes {
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                return keyWindow
            }
        }
        for scene in foregroundScenes {
            if let firstWindow = scene.windows.first {
                return firstWindow
            }
        }
        for scene in windowScenes {
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                return keyWindow
            }
        }
        return windowScenes.first?.windows.first
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
            if activeController?.id == controllerId {
                activeController = nil
            }
        } else {
            kerror("Received request to deactivate non existent controller: \(controllerId)")
        }
    }

    /// Creates and connects the on-screen virtual controller, unless it is
    /// disallowed (e.g. on a Mac) — in which case it's never created, so its view
    /// never appears. Runs its work on the main thread (synchronously if already
    /// there, so a runtime enable can activate it immediately afterwards).
    private func createVirtualController() {
        guard allowVirtualController else {
            kinfo("Virtual controller disallowed; not creating")
            return
        }
        kinfo("Creating virtual controller")
        let work = { [weak self] in
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
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            if let activeController = self.activeController,
                                activeController.id == newVirtualController.identifier
                            {
                                self.deactivateController(controllerId: activeController.id)
                            }
                            self.allControllers.removeAll(where: { $0.id == newVirtualController.identifier })
                            if self.virtualController?.identifier == newVirtualController.identifier {
                                self.virtualController = nil
                            }
                            if self.allowVirtualController,
                                self.virtualControllerConnectAttempts < self.maxVirtualControllerConnectAttempts
                            {
                                self.virtualControllerConnectAttempts += 1
                                let retryDelay = 0.5 * Double(self.virtualControllerConnectAttempts)
                                kinfo("Retrying virtual controller connect in \(retryDelay)s (attempt \(self.virtualControllerConnectAttempts)/\(self.maxVirtualControllerConnectAttempts))")
                                DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                                    self?.createVirtualController()
                                }
                            }
                        }
                        return
                    } else {
                        kinfo("Successfully connected virtual controller")
                        self.virtualControllerConnectAttempts = 0
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { return }
                            if self.activeController?.isVirtual ?? false {
                                self.enableVirtualControllerView()
                            }
                        }
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

                if self.activeController == nil {
                    kinfo("Activating newly created virtual controller")
                    self.enableControllerById(newVirtualController.identifier)
                }

                if self.activeController?.isVirtual ?? false {
                    kinfo("Keeping virtual controller view enabled for the active controller")
                    enableVirtualControllerView()
                } else {
                    kinfo("Virtual controller created but not active; hiding its view")
                    disableVirtualControllerView()
                }
            }
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    /// Tears down the on-screen virtual controller (deactivating it first if it is
    /// the active controller), so its view disappears. Used when the virtual
    /// controller is disabled at runtime.
    func removeVirtualController() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in self?.removeVirtualController() }
            return
        }
        guard let controller = virtualController else { return }
        if activeController?.isVirtual ?? false {
            deactivateController(controllerId: controller.identifier)
        }
        disableVirtualControllerView()
        controller.disconnect()
        allControllers.removeAll(where: { $0.isVirtual })
        virtualController = nil
    }

    /// Creates the virtual controller on demand if allowed and not already present
    /// (e.g. when re-enabled at runtime).
    func ensureVirtualController() {
        createVirtualController()
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
                kerror("Received notification to disconnect Apple Touch Controller")
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
        // Prefer a physical controller; only fall back to the virtual one when it
        // is allowed. With it disallowed and no physical controller, nothing is
        // activated (keyboard/touch input is unaffected).
        let sorted = allControllers.sorted(by: { (a, b) in !a.isVirtual && b.isVirtual })
        let defaultController = allowVirtualController
            ? sorted.first
            : sorted.first(where: { !$0.isVirtual })
        if let defaultController {
            enableControllerById(defaultController.id)
        }
    }

    public func enableControllerById(_ controllerId: String) {
        kinfo("Enabling controller \(controllerId)")
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.enableControllerById(controllerId)
            }
            return
        }

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

    public func disableController() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.disableController()
            }
            return
        }
        if let activeController = self.activeController {
            self.deactivateController(controllerId: activeController.id)
        }
        self.activeController = nil
    }

    private func enqueueButtonEvent(_ button: KControllerEventButtonType, pressed: Bool) {
        let event = KEvent.input(.controller(.button(KControllerEventButton(
            button: button,
            state: pressed ? .pressed : .released
        ))))
        eventQueue.enqueue(item: event)
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
            self?.enqueueButtonEvent(.buttonA, pressed: pressed)
        }

        gamepad.buttonB.valueChangedHandler = { [weak self] button, value, pressed in
            self?.enqueueButtonEvent(.buttonB, pressed: pressed)
        }

        gamepad.buttonX.valueChangedHandler = { [weak self] button, value, pressed in
            self?.enqueueButtonEvent(.buttonX, pressed: pressed)
        }

        gamepad.buttonY.valueChangedHandler = { [weak self] button, value, pressed in
            self?.enqueueButtonEvent(.buttonY, pressed: pressed)
        }

        gamepad.buttonMenu.valueChangedHandler = { [weak self] button, value, pressed in
            self?.enqueueButtonEvent(.buttonStart, pressed: pressed)
        }

        gamepad.buttonOptions?.valueChangedHandler = { [weak self] button, value, pressed in
            self?.enqueueButtonEvent(.buttonStart, pressed: pressed)
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
        gamepad.buttonMenu.valueChangedHandler = nil
        gamepad.buttonOptions?.valueChangedHandler = nil

        gamepad.leftThumbstick.valueChangedHandler = nil
        gamepad.rightThumbstick.valueChangedHandler = nil
    }

    private func enableVirtualControllerView(retriesRemaining: Int = 8) {
        kinfo("Enabling Virtual Controller View")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let window = self.activeWindow() {
                func enableControllerView(from view: UIView) -> Bool {
                    if String(describing: type(of: view)) == "GCControllerView" {
                        kinfo("Enabling GCView")
                        view.isUserInteractionEnabled = true
                        if view.alpha == 0 && self.virtualControllerFadeTime > 0 {
                            UIView.animate(withDuration: self.virtualControllerFadeTime, delay: 0, options: .curveEaseIn) {
                                view.alpha = 1
                            }
                        } else {
                            view.alpha = 1
                        }
                        return true
                    }
                    for subview in view.subviews {
                        if enableControllerView(from: subview) {
                            return true
                        }
                    }
                    return false
                }
                if enableControllerView(from: window) {
                    return
                }
            }

            if retriesRemaining > 0, self.allowVirtualController, self.activeController?.isVirtual ?? false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.enableVirtualControllerView(retriesRemaining: retriesRemaining - 1)
                }
            }
        }
    }

    private func disableVirtualControllerView() {
        kinfo("Disabling Virtual Controller View")
        DispatchQueue.main.async {
            if let window = self.activeWindow() {
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
