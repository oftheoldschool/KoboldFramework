import Foundation
public enum KLogLevel: Int {
    case trace
    case debug
    case info
    case warn
    case error
    case fatal
    case disabled
}

public var kGlobalLogLevel: KLogLevel = .info

@inlinable
func ktrace(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if KLogLevel.trace.rawValue >= kGlobalLogLevel.rawValue {
        klog(level: "trace", items, separator: separator, terminator: terminator)
    }
}
@inlinable
func kdebug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if KLogLevel.debug.rawValue >= kGlobalLogLevel.rawValue {
        klog(level: "debug", items, separator: separator, terminator: terminator)
    }
}

@inlinable
func kinfo(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if KLogLevel.info.rawValue >= kGlobalLogLevel.rawValue {
        klog(level: "info ", items, separator: separator, terminator: terminator)
    }
}

@inlinable
func kwarn(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if KLogLevel.warn.rawValue >= kGlobalLogLevel.rawValue {
        klog(level: "warn ", items, separator: separator, terminator: terminator)
    }
}

@inlinable
func kerror(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if KLogLevel.error.rawValue >= kGlobalLogLevel.rawValue{
        klog(level: "error", items, separator: separator, terminator: terminator)
    }
}

@inlinable
func kfatal(_ items: Any..., separator: String = " ", terminator: String = "\n") -> Never {
    if KLogLevel.fatal.rawValue >= kGlobalLogLevel.rawValue{
        klog(level: "fatal", items, separator: separator, terminator: terminator)
    }
    let fatalErrorMessage = items.reduce("\n") { (acc, next) in String(describing: next) + acc }
    fatalError(fatalErrorMessage)
}

@inlinable
func kunimplemented() -> Never {
    kfatal("not implemented")
}

@inlinable
func klog(level: String, _ items: Any..., separator: String = " ", terminator: String = "\n") {
    print([timestamp(), "[\(level)] :"] + items, separator: separator, terminator: terminator)
}

@inlinable
func timestamp() -> String {
    // todo: this should be constant...
    let date = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss"
    return dateFormatter.string(from: date)
}
