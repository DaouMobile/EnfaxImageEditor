import UIKit
import Geometry2D

final class ImageEditorViewModel: Store<ImageEditorState> {
    func back() {
        self.commit { state in
            state.navigation = .pop
        }
    }
    
    func attach() {
        self.commit { state in
            let images: [JPEGImage] = state.editingImages
                .map { (editingImage) in
                    let imageData = self.rotate(imageData: editingImage.cropped?.imageData ?? editingImage.original.data, by: editingImage.orientation)
                    return JPEGImage(name: editingImage.original.name, data: imageData)
                }
            state.completion(images)
            state.navigation = .dismiss
        }
    }
    
    func rotate() {
        self.commit { state in
            state.editingImages[state.currentImageIndex].orientation = state.editingImages[state.currentImageIndex].orientation.clockwiselyRotated
        }
    }
    
    func crop() {
        self.commit { state in
            let currentEditingImage = state.editingImages[state.currentImageIndex]
            if let (_, croppedArea) = currentEditingImage.cropped {
                state.navigation = .cropper(currentEditingImage.original.data, croppedArea, currentEditingImage.orientation)
            } else {
                state.navigation = .cropper(currentEditingImage.original.data, nil, currentEditingImage.orientation)
            }
        }
    }
    
    func tapBackground() {
        self.commit { state in
            state.toolBarHidden.toggle()
        }
    }
    
    func setIndex(_ index: Int) {
        self.commit { state in
            state.currentImageIndex = index
        }
    }
    
    func clearNavigation() {
        self.commit { state in
            state.navigation = nil
        }
    }
    
    func setToolBarHidden(_ toolBarHidden: Bool) {
        self.commit { state in
            state.toolBarHidden = toolBarHidden
        }
    }
    
    func receiveCroppedImage(data: Data, croppedArea: Square) {
        self.commit { state in
            state.editingImages[state.currentImageIndex].cropped = (data, croppedArea)
        }
    }
    
    private func rotate(imageData: Data, by orientation: EditingImage.Orientation) -> Data {
        guard orientation != .up, let rotatedImageData = UIImage(data: imageData)?.orientationFixed.rotated(by: orientation.radian).jpegData(compressionQuality: 1.0) else {
            return imageData
        }
        return rotatedImageData
    }
}
