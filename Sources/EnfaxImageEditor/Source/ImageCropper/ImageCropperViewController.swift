import UIKit
import RxSwift
import RxGesture
import Geometry2D

final class ImageCropperViewController: UIViewController {
    static let vertexSize: CGFloat = 20
    
    @IBOutlet private(set) weak var backButton: UIButton!
    
    @IBOutlet private(set) weak var completeButton: UIButton!
    
    @IBOutlet private(set) weak var imageView: UIImageView!
    
    @IBOutlet private(set) weak var documentAreaImageView: UIImageView!
    
    @IBOutlet private(set) weak var refreshButton: UIButton!
    
    private let topLeftView: UIView = .init(frame: .init(origin: .zero, size: .init(width: vertexSize, height: vertexSize)))
    
    private let topRightView: UIView = .init(frame: .init(origin: .zero, size: .init(width: vertexSize, height: vertexSize)))
    
    private let bottomLeftView: UIView = .init(frame: .init(origin: .zero, size: .init(width: vertexSize, height: vertexSize)))
    
    private let bottomRightView: UIView = .init(frame: .init(origin: .zero, size: .init(width: vertexSize, height: vertexSize)))
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private(set) var viewModel: ImageCropperViewModel!
    
    let dispatchQueue: DispatchQueue = .global(qos: .userInteractive)
    
    private let disposeBag: DisposeBag = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [self.topLeftView, self.topRightView, self.bottomLeftView, self.bottomRightView].forEach { (view) in
            view.backgroundColor = .enfaxBlue
            view.layer.cornerRadius = Self.vertexSize / 2.0
            self.documentAreaImageView.addSubview(view)
        }
        
        self.imageView.image = UIImage(data: self.viewModel.state.imageData)?.rotated(by: self.viewModel.state.orientation.radian)
        
        self.documentAreaImageView.isHidden = true
        
        self.bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.render(documentArea: self.viewModel.state.documentArea, orientation: self.viewModel.state.orientation)
        self.documentAreaImageView.isHidden = false
    }
    
    func setup(imageData: Data, croppedArea: Square?, orientation: EditingImage.Orientation, completion: @escaping (Data, Square) -> Void) {
        let initialState: ImageCropperState = .init(imageData: imageData, documentArea: croppedArea, orientation: orientation, completion: completion)
        self.viewModel = .init(initialState: initialState)
        
        if croppedArea == nil {
            _ = self.viewModel.dispatch(self.viewModel.extract())
                .subscribe()
        }
    }
    
    @IBAction func back() {
        self.viewModel.commit(self.viewModel.back())
    }
    
    @IBAction func complete() {
        self.viewModel.commit(self.viewModel.complete())
    }
    
    @IBAction func refresh() {
        self.viewModel.commit(self.viewModel.refresh())
    }
    
    private func bind() {
        self.viewModel.stateDriver
            .map { $0.navigation }
            .distinctUntilChanged()
            .drive(with: self) { (owner, navigation) in
                guard let navigation = navigation else {
                    return
                }
                switch navigation {
                case .dismiss:
                    owner.dismiss(animated: true, completion: nil)
                }
            }
            .disposed(by: self.disposeBag)
        
        self.viewModel.stateDriver
            .map { $0.documentArea }
            .distinctUntilChanged()
            .drive(with: self) { (owner, documentArea) in
                owner.render(documentArea: documentArea, orientation: owner.viewModel.state.orientation)
            }
            .disposed(by: self.disposeBag)
        
        self.documentAreaImageView.rx.panGesture().when(.began, .changed, .ended)
            .subscribe(with: self) { (owner, recognizer) in
                owner.pan(recognizer)
            }
            .disposed(by: self.disposeBag)
    }
    
    private func pan(_ recognizer: UIPanGestureRecognizer) {
        let point: Point = recognizer.location(in: self.documentAreaImageView).point
        
        let contentImageRect = self.imageView.contentClippingRect
        
        if recognizer.state == .began {
            guard let documentArea: Square = self.viewModel.state.documentArea else {
                return
            }
            let scaledDocumentArea = self.transformForView(square: documentArea, in: contentImageRect, by: self.viewModel.state.orientation)
            guard let targetIndexWithDistance = scaledDocumentArea.vertices.enumerated().reduce((Int, Double)?.none, { partialResult, element in
                let (index, vertex) = element
                let distance = point.distance(to: vertex)
                
                guard let (lastIndex, lastDistance) = partialResult else {
                    if distance < 40 {
                        return (index, distance)
                    } else {
                        return nil
                    }
                }
                if lastDistance > distance {
                    return (index, distance)
                } else {
                    return (lastIndex, lastDistance)
                }
            }) else {
                return
            }
            
            self.viewModel.commit { state in
                state.selectedVertexIndex = targetIndexWithDistance.0
            }
            return
        } else if recognizer.state == .ended {
            self.viewModel.commit { state in
                state.selectedVertexIndex = nil
            }
        } else if let index = self.viewModel.state.selectedVertexIndex {
            self.viewModel.commit { state in
                guard var square = state.documentArea?.rotated(by: state.orientation) else {
                    return
                }
                let point = self.transformForViewModel(point: point, in: contentImageRect)
                switch index {
                case 0:
                    guard let relativePositionToDiagonal = Line(passThrough: square.secondVertex, and: square.fourthVertex)?.relativePosition(of: point), relativePositionToDiagonal.x < 0, relativePositionToDiagonal.y > 0 else {
                        return
                    }
                    guard let relativePositionToVertical = Line(passThrough: square.secondVertex, and: square.thirdVertex)?.relativePosition(of: point), relativePositionToVertical.x < 0, point.x < square.secondVertex.x, point.x < square.thirdVertex.x else {
                        return
                    }
                    guard let relativePositionToHorizontal = Line(passThrough: square.thirdVertex, and: square.fourthVertex)?.relativePosition(of: point), relativePositionToHorizontal.y > 0, point.y > square.thirdVertex.y, point.y > square.fourthVertex.y else {
                        return
                    }
                    square.firstVertex = point
                case 1:
                    guard let relativePositionToDiagonal = Line(passThrough: square.firstVertex, and: square.thirdVertex)?.relativePosition(of: point), relativePositionToDiagonal.x > 0, relativePositionToDiagonal.y > 0 else {
                        return
                    }
                    guard let relativePositionToVertical = Line(passThrough: square.firstVertex, and: square.fourthVertex)?.relativePosition(of: point), relativePositionToVertical.x > 0, point.x > square.firstVertex.x, point.x > square.fourthVertex.x else {
                        return
                    }
                    guard let relativePositionToHorizontal = Line(passThrough: square.thirdVertex, and: square.fourthVertex)?.relativePosition(of: point), relativePositionToHorizontal.y > 0, point.y > square.thirdVertex.y, point.y > square.fourthVertex.y else {
                        return
                    }
                    square.secondVertex = point
                case 2:
                    guard let relativePositionToDiagonal = Line(passThrough: square.secondVertex, and: square.fourthVertex)?.relativePosition(of: point), relativePositionToDiagonal.x > 0, relativePositionToDiagonal.y < 0 else {
                        return
                    }
                    guard let relativePositionToVertical = Line(passThrough: square.firstVertex, and: square.fourthVertex)?.relativePosition(of: point), relativePositionToVertical.x > 0, point.x > square.firstVertex.x, point.x > square.fourthVertex.x else {
                        return
                    }
                    guard let relativePositionToHorizontal = Line(passThrough: square.firstVertex, and: square.secondVertex)?.relativePosition(of: point), relativePositionToHorizontal.y < 0, point.y < square.firstVertex.y, point.y < square.secondVertex.y else {
                        return
                    }
                    square.thirdVertex = point
                case 3:
                    guard let relativePositionToDiagonal = Line(passThrough: square.firstVertex, and: square.thirdVertex)?.relativePosition(of: point), relativePositionToDiagonal.x < 0, relativePositionToDiagonal.y < 0 else {
                        return
                    }
                    guard let relativePositionToVertical = Line(passThrough: square.secondVertex, and: square.thirdVertex)?.relativePosition(of: point), relativePositionToVertical.x < 0, point.x < square.secondVertex.x, point.x < square.thirdVertex.x else {
                        return
                    }
                    guard let relativePositionToHorizontal = Line(passThrough: square.firstVertex, and: square.secondVertex)?.relativePosition(of: point), relativePositionToHorizontal.y < 0, point.y < square.firstVertex.y, point.y < square.secondVertex.y else {
                        return
                    }
                    square.fourthVertex = point
                default:
                    return
                }
                state.documentArea = square.rotated(by: -state.orientation)
            }
        }
    }
    
    private func render(documentArea: Square?, orientation: EditingImage.Orientation) {
        guard let documentArea = documentArea else {
            self.documentAreaImageView.image = nil
            return
        }
        
        let contentImageRect: CGRect = self.imageView.contentClippingRect
        
        let scaledDocumentArea = self.transformForView(square: documentArea, in: contentImageRect, by: orientation)
        
        let renderer: UIGraphicsImageRenderer = .init(bounds: .init(origin: .zero, size: self.imageView.bounds.size))
        
        let image = renderer.image { context in
            context.cgContext.setLineWidth(3)
            context.cgContext.move(to: .init(scaledDocumentArea.firstVertex))
            context.cgContext.addLine(to: .init(scaledDocumentArea.secondVertex))
            context.cgContext.addLine(to: .init(scaledDocumentArea.thirdVertex))
            context.cgContext.addLine(to: .init(scaledDocumentArea.fourthVertex))
            context.cgContext.addLine(to: .init(scaledDocumentArea.firstVertex))
            context.cgContext.setStrokeColor(UIColor.enfaxBlue.cgColor)
            context.cgContext.strokePath()
        }
        self.documentAreaImageView.image = image
        
        self.topLeftView.center = CGPoint(scaledDocumentArea.firstVertex)
        self.topRightView.center = CGPoint(scaledDocumentArea.secondVertex)
        self.bottomRightView.center = CGPoint(scaledDocumentArea.thirdVertex)
        self.bottomLeftView.center = CGPoint(scaledDocumentArea.fourthVertex)
    }
    
    private func transformForView(square: Square, in rect: CGRect, by orientation: EditingImage.Orientation) -> Square {
        return square.rotated(by: orientation)
            .reflected(over: .horizontal(yIntercept: 0.5))
            .scaled(by: .init(x: rect.width, y: rect.height))
            .translated(by: rect.origin.position)
    }
    
    private func transformForViewModel(point: Point, in rect: CGRect) -> Point {
        return point
            .translated(by: -rect.origin.position)
            .scaled(by: .init(x: 1 / rect.width, y: 1 / rect.height))
            .reflected(over: .horizontal(yIntercept: 0.5))
            .ranged(from: .zero, to: .init(x: 1, y: 1))
    }
}
