import Foundation
import Geometry2D

struct EditingImage {
    enum Orientation: Equatable {
        case up
        case right
        case down
        case left
        
        var radian: Double {
            switch self {
            case .up:
                return .zero
            case .right:
                return .pi / 2
            case .down:
                return .pi
            case .left:
                return .pi / 2 * 3
            }
        }
        
        var clockwiselyRotated: Orientation {
            switch self {
            case .up:
                return .right
            case .right:
                return .down
            case .down:
                return .left
            case .left:
                return .up
            }
        }
        
        prefix static func - (value: Orientation) -> Orientation {
            switch value {
            case .up, .down:
                return value
            case .right:
                return .left
            case .left:
                return .right
            }
        }
    }
    
    typealias Cropped = (imageData: Data, area: Square)
    
    var original: JPEGImage
    var cropped: Cropped?
    var orientation: Orientation = .up
    
    var imageData: Data {
        return self.cropped?.imageData ?? self.original.data
    }
}
