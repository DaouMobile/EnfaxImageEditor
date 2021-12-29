import UIKit
import RxSwift
import SnapKit

class ImageEditorContentViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    
    private(set) var viewModel: ImageEditorViewModel!
    
    private(set) var index: Int!
    
    let disposeBag: DisposeBag = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        
        let editingImage: EditingImage = self.viewModel.state.editingImages[self.index]
        self.imageView.image = .init(data: editingImage.imageData)
        self.imageView.transform = .init(rotationAngle: .init(editingImage.orientation.radian))
        
        self.bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.adjustConstraints(orientation: self.viewModel.state.editingImages[self.index].orientation, animate: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.scrollView.zoomScale = 1
    }
    
    func setup(viewModel: ImageEditorViewModel, index: Int) {
        self.viewModel = viewModel
        self.index = index
    }
    
    func render(_ state: ImageEditorState) {
        let editingImage: EditingImage = state.editingImages[self.index]
        
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) {
            self.imageView.transform = .init(rotationAngle: .init(editingImage.orientation.radian))
            self.view.layoutIfNeeded()
        }
    }
    
    private func bind() {
        self.viewModel.stateDriver
            .compactMap { [weak self] (state) in
                guard let self = self else {
                    return nil
                }
                let imageData = state.editingImages[self.index].imageData
                return UIImage(data: imageData)
            }
            .distinctUntilChanged()
            .drive(self.imageView.rx.image)
            .disposed(by: self.disposeBag)
        
        self.viewModel.stateDriver
            .compactMap { [weak self] (state) -> EditingImage.Orientation? in
                guard let self = self else { return nil }
                return state.editingImages[self.index].orientation
            }
            .distinctUntilChanged()
            .drive(with: self) { (owner, orientation) in
                owner.adjustConstraints(orientation: orientation, animate: true)
            }
            .disposed(by: self.disposeBag)
        
        self.scrollView.rx.didZoom
            .bind(with: self.viewModel, onNext: { viewModel, _ in
                viewModel.setToolBarHidden(true)
            })
            .disposed(by: self.disposeBag)
    }
    
    private func adjustConstraints(orientation: EditingImage.Orientation, animate: Bool) {
        let rotation: CGAffineTransform = .init(rotationAngle: orientation.radian)
        let rotatedBounds = self.contentView.bounds.applying(rotation)
        func adjustConstraints() {
            self.imageView.transform = rotation
            self.imageViewHeightConstraint.constant = rotatedBounds.height - self.contentView.bounds.height
            self.imageViewWidthConstraint.constant = rotatedBounds.width - self.contentView.bounds.width
        }
        if animate {
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.25) {
                adjustConstraints()
                self.view.layoutIfNeeded()
            }
        } else {
            adjustConstraints()
        }
    }
}

extension ImageEditorContentViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }
}
