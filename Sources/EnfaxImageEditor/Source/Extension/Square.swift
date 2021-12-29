import Geometry2D

extension Square {
    mutating func rotate(by orientation: EditingImage.Orientation) {
        guard orientation != .up else {
            return
        }
        self.translate(by: .init(x: -0.5, y: -0.5))
        switch orientation {
        case .right:
            let tmp = self.firstVertex
            self.firstVertex = self.fourthVertex
            self.fourthVertex = self.thirdVertex
            self.thirdVertex = self.secondVertex
            self.secondVertex = tmp
            self.commit { vector in
                let originalVector = vector
                vector.x = originalVector.y
                vector.y = -originalVector.x
            }
        case .down:
            var tmp = self.firstVertex
            self.firstVertex = self.thirdVertex
            self.thirdVertex = tmp
            tmp = self.secondVertex
            self.secondVertex = self.fourthVertex
            self.fourthVertex = tmp
            self.commit { vector in
                let originalVector = vector
                vector.x = -originalVector.x
                vector.y = -originalVector.y
            }
        case .left:
            let tmp = self.firstVertex
            self.firstVertex = self.secondVertex
            self.secondVertex = self.thirdVertex
            self.thirdVertex = self.fourthVertex
            self.fourthVertex = tmp
            self.commit { vector in
                let originalVector = vector
                vector.x = -originalVector.y
                vector.y = originalVector.x
            }
        default:
            // do nothing
            break
        }
        self.translate(by: .init(x: 0.5, y: 0.5))
    }
    
    func rotated(by orientation: EditingImage.Orientation) -> Square {
        var newSquare = self
        newSquare.rotate(by: orientation)
        return newSquare
    }
}
