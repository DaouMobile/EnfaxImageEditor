import CoreGraphics
import Geometry2D

extension CGPoint {
    var point: Point {
        return .init(x: self.x, y: self.y)
    }
    
    var position: Vector {
        return .init(x: self.x, y: self.y)
    }
    
    init(_ point: Point) {
        self.init(x: point.x, y: point.y)
    }
    
    init(_ position: Vector) {
        self.init(x: position.x, y: position.y)
    }
}
