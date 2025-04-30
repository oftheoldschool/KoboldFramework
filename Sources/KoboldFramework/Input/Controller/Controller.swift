import GameController

public struct KController: Hashable {
    public enum KRawController {
        case virtual(GCVirtualController)
        case physical(GCController)
    }

    public let id: String
    public let description: String
    public let rawController: KRawController

    init(_ controller: GCController) {
        self.id = controller.identifier
        self.description = controller.name
        self.rawController = .physical(controller)
    }

    init(_ controller: GCVirtualController) {
        self.id = controller.identifier
        self.description = controller.name
        self.rawController = .virtual(controller)
    }

    public var isVirtual: Bool {
        return if case .virtual = rawController {
            true
        } else {
            false
        }
    }

    var gcController: GCController? {
        return switch rawController {
        case .virtual(let virtualController): virtualController.controller
        case .physical(let controller): controller
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: KController, rhs: KController) -> Bool {
        return lhs.id == rhs.id
    }
}
