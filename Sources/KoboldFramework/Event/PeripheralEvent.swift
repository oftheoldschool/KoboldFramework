public enum KPeripheralEvent {
    case connected(KPeripheralConnectedEvent)
    case disconnected(KPeripheralDisconnectedEvent)
}

public enum KPeripheralType {
    case physicalController
    case virtualController
}

public struct KPeripheralConnectedEvent {
    let peripheralType: KPeripheralType
}

public struct KPeripheralDisconnectedEvent {
    let peripheralType: KPeripheralType
}
