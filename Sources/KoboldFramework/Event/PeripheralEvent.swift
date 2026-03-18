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
    public let peripheralType: KPeripheralType
    public let identifier: String
}

public struct KPeripheralDisconnectedEvent {
    public let peripheralType: KPeripheralType
    public let identifier: String
}
