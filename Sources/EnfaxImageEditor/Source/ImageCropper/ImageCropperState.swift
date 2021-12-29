import Geometry2D

struct ImageCropperState {
    enum Navigation: Equatable {
        case dismiss
    }
    
    var imageData: Data
    var documentArea: Square?
    var selectedVertexIndex: Int?
    var orientation: EditingImage.Orientation
    var completion: (EditingImage.Cropped) -> Void
    var navigation: Navigation?
}
