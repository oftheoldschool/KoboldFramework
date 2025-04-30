import GameController

extension GCController {
    var identifier: String { description }
    var name: String { vendorName ?? description }
}

extension GCVirtualController {
    var identifier: String { description }
    var name: String { "Apple Touch Controller" }
}
