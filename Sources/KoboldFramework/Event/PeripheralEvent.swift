public enum KPeripheralEvent {
    case connected(KPeripheralConnectedEvent)
    case disconnected(KPeripheralDisconnectedEvent)
}

public enum KPeripheralType {
    case physicalController
    case virtualController
    case keyboard
    case mouse
}

public struct KPeripheralConnectedEvent {
    let peripheralType: KPeripheralType
    let identifier: String
}

public struct KPeripheralDisconnectedEvent {
    let peripheralType: KPeripheralType
    let identifier: String
}
