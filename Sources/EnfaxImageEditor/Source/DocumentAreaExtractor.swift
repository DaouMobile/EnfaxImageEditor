import Foundation
import RxSwift
import Geometry2D

protocol DocumentAreaExtractor {
    func extract(from imageData: Data) -> Single<[Square]>
}

import Vision

class VisionDocumentAreaExtractor: DocumentAreaExtractor {
    enum Error: Swift.Error {
        case invalidData
    }
    
    func extract(from imageData: Data) -> Single<[Square]> {
        guard let uiImage: UIImage = .init(data: imageData), let cgImage: CGImage = uiImage.cgImage else {
            return .error(Error.invalidData)
        }
        return self.extract(from: cgImage).map { $0.map { $0.square } }
    }
    
    private func extract(from image: CGImage) -> Single<[VNRectangleObservation]> {
        return .create { (observer) in
            do {
                let request: VNImageBasedRequest = self.createDetectRectanglesRequest { result in
                    do {
                        let observations = try result.get()
                        observer(.success(observations))
                    } catch {
                        observer(.failure(error))
                    }
                }
                let handler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
                try handler.perform([request])
                return Disposables.create {
                    if #available(iOS 13, *) {
                        request.cancel()
                    }
                }
            } catch {
                observer(.failure(error))
                return Disposables.create()
            }
        }
    }
    
    @available(iOS 15, *)
    private func createDetectDocumentSegmentationRequest(completion: @escaping (Result<[VNRectangleObservation], Swift.Error>) -> Void) -> VNImageBasedRequest {
        return VNDetectDocumentSegmentationRequest { (request, error) in
            if let error = error {
                completion(.failure(error))
            } else if let request = request as? VNDetectDocumentSegmentationRequest, let observations = request.results {
                completion(.success(observations))
            }
        }
    }
    
    private func createDetectRectanglesRequest(completion: @escaping (Result<[VNRectangleObservation], Swift.Error>) -> Void) -> VNImageBasedRequest {
        let request = VNDetectRectanglesRequest { (request, error) in
            if let error = error {
                completion(.failure(error))
            } else if let request = request as? VNDetectRectanglesRequest, let observations = request.results {
                completion(.success(observations))
            }
        }
        request.minimumConfidence = 0.2
        return request
    }
}
