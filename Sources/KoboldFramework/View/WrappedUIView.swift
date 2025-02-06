import SwiftUI

public struct KWrappedUIView: UIViewRepresentable {
    public var wrappedView: UIView
    private var handleUpdateUIView: ((UIView, Context) -> Void)?
    private var handleMakeUIView: ((Context) -> UIView)?
    
    public init(closure: () -> UIView) {
        wrappedView = closure()
    }
    
    public func makeUIView(context: Context) -> UIView {
        return handleMakeUIView.map { handler in 
            handler(context)
        } ?? wrappedView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        handleUpdateUIView?(uiView, context)
    }
}

public extension KWrappedUIView {
    mutating func setMakeUIView(handler: @escaping (Context) -> UIView) -> Self {
        handleMakeUIView = handler
        return self
    }
    
    mutating func setUpdateUIView(handler: @escaping (UIView, Context) -> Void) -> Self {
        handleUpdateUIView = handler
        return self
    }
}
