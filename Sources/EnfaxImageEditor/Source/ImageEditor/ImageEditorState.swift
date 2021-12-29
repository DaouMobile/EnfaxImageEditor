import Geometry2D

struct ImageEditorState {
    enum Navigation: Equatable {
        case pop
        case dismiss
        case cropper(Data, Square?, EditingImage.Orientation)
    }
    
    var toolBarHidden: Bool = false
    var editingImages: [EditingImage]
    var currentImageIndex: Int = 0
    var completion: ([JPEGImage]) -> Void
    var navigation: Navigation?
    
    var imageCount: Int {
        return self.editingImages.count
    }
}
