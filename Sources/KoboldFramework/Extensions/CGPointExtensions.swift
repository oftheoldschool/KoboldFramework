import Foundation

extension CGPoint {
    public func toFloatPair() -> (x: Float, y: Float) {
        return (x: Float(self.x), y: Float(self.y))
    }    
}
