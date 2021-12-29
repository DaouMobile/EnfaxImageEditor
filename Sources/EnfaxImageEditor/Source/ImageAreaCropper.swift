import Foundation
import Geometry2D

protocol ImageAreaCropper {
    func crop(_ area: Square, in imageData: Data) -> Data?
}

import CoreImage
import UIKit

struct VisionImageAreaCropper: ImageAreaCropper {
    func crop(_ areaRatio: Square, in imageData: Data) -> Data? {
        guard let cgImage: CGImage = UIImage(data: imageData)?.cgImage else {
            print("cgImage is nil")
            return nil
        }
        let ciImage: CIImage = .init(cgImage: cgImage)
        let ciImageExtent = ciImage.extent
        let area: Square = areaRatio.scaled(by: .init(x: ciImageExtent.width, y: ciImageExtent.height))
        let croppedCIImage: CIImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(x: area.firstVertex.x, y: area.firstVertex.y),
            "inputTopRight": CIVector(x: area.secondVertex.x, y: area.secondVertex.y),
            "inputBottomRight": CIVector(x: area.thirdVertex.x, y: area.thirdVertex.y),
            "inputBottomLeft": CIVector(x: area.fourthVertex.x, y: area.fourthVertex.y),
        ])
        let context: CIContext = .init()
        guard let croppedCGImage: CGImage = context.createCGImage(croppedCIImage, from: croppedCIImage.extent) else {
            print("croppedCGImage is nil")
            return nil
        }
        return UIImage(cgImage: croppedCGImage).jpegData(compressionQuality: 1.0)
    }
}
