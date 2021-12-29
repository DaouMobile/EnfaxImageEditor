import Foundation
import Geometry2D

final class ImageCropperViewModel: Store<ImageCropperState> {
    let documentAreaExtractor: DocumentAreaExtractor = VisionDocumentAreaExtractor()
    let imageAreaCropper: ImageAreaCropper = VisionImageAreaCropper()
    
    func extract() -> Action {
        let imageData: Data = self.state.imageData
        return self.documentAreaExtractor.extract(
            from: imageData
        ).map { [weak self] (documentAreas) -> Mutation? in
            guard let self = self else {
                return nil
            }
            if let documentArea = documentAreas.first {
                return self.receiveDocumentArea(documentArea)
            } else {
                return self.refresh()
            }
        }.asObservable().compactMap { $0 }
    }
    
    func back() -> Mutation {
        return { state in
            state.navigation = .dismiss
        }
    }
    
    func complete() -> Mutation {
        return { state in
            guard let documentArea = state.documentArea else {
                return
            }
            let imageData = state.imageData
            guard let croppedImageData = self.imageAreaCropper.crop(documentArea, in: imageData) else {
                return
            }
            state.completion((croppedImageData, documentArea))
            state.navigation = .dismiss
        }
    }
    
    func refresh() -> Mutation {
        return { state in
            state.documentArea = .init(
                firstVertex: .init(x: 0, y: 1),
                secondVertex: .init(x: 1, y: 1),
                thirdVertex: .init(x: 1, y: 0),
                fourthVertex: .origin
            )
        }
    }
    
    private func receiveDocumentArea(_ documentArea: Square) -> Mutation {
        return { state in
            state.documentArea = documentArea
        }
    }
}
