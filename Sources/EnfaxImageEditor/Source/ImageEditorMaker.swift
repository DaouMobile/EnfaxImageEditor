import UIKit

public class ImageEditorMaker {
    public init() {}
    
    public func callAsFunction(images: [JPEGImage], completion: @escaping ([JPEGImage]) -> Void) -> UIViewController? {
        guard let vc = UIStoryboard(name: "ImageEditor", bundle: .main).instantiateInitialViewController() as? ImageEditorViewController else {
            return nil
        }
        vc.modalTransitionStyle = .crossDissolve
        vc.setup(images: images, completion: completion)
        return vc
    }
    
    public func callAsFunction(image: JPEGImage, completion: @escaping (JPEGImage) -> Void) -> UIViewController? {
        guard let vc = self.callAsFunction(images: [image], completion: { jpegImages in
            completion(jpegImages[0])
        }) as? ImageEditorViewController else {
            return nil
        }
        vc.viewModel.commit { state in
            state.navigation = .cropper(image.data, nil, .up)
        }
        return vc
    }
}
