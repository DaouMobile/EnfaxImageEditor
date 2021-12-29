import UIKit
import RxSwift
import RxCocoa
import RxGesture

class ImageEditorViewController: UIViewController {
    @IBOutlet weak var headerBackgroundView: UIVisualEffectView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var attachButton: UIButton!
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    @IBOutlet weak var footerBackgroundView: UIVisualEffectView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var rotateButton: UIButton!
    @IBOutlet weak var cropButton: UIButton!
    
    private(set) var viewModel: ImageEditorViewModel!
    
    private let disposeBag: DisposeBag = .init()
    
    override var prefersStatusBarHidden: Bool {
        return self.viewModel.state.toolBarHidden
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super .viewDidLoad()
        
        self.bind()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ImageEditorPageViewController {
            destination.setup(viewModel: self.viewModel)
        }
        super.prepare(for: segue, sender: sender)
    }
    
    func setup(images: [JPEGImage], completion: @escaping ([JPEGImage]) -> Void) {
        let initialState: ImageEditorState = .init(editingImages: images.map { .init(original: $0) }, completion: completion)
        self.viewModel = .init(initialState: initialState)
    }
    
    @IBAction
    func back() {
        self.viewModel.back()
    }
    
    @IBAction
    func attach() {
        self.viewModel.attach()
    }
    
    @IBAction
    func rotate() {
        self.viewModel.rotate()
    }
    
    @IBAction
    func crop() {
        self.viewModel.crop()
    }
    
    @IBAction
    func tapBackground() {
        self.viewModel.tapBackground()
    }
    
    private func bind() {
        self.viewModel.stateDriver
            .map { $0.toolBarHidden }
            .distinctUntilChanged()
            .drive(with: self) { (owner, toolBarHidden) in
                owner.setNeedsStatusBarAppearanceUpdate()
                owner.view.layoutIfNeeded()
                UIView.animate(withDuration: 0.25) {
                    owner.headerBackgroundView.alpha = toolBarHidden ? 0 : 1
                    owner.headerView.alpha = toolBarHidden ? 0 : 1
                    owner.footerBackgroundView.alpha = toolBarHidden ? 0 : 1
                    owner.footerView.alpha = toolBarHidden ? 0 : 1
                    owner.view.layoutIfNeeded()
                }
            }
            .disposed(by: self.disposeBag)
        
        self.viewModel.stateDriver
            .map { $0.currentImageIndex }
            .distinctUntilChanged()
            .drive(with: self) { (owner, currentImageIndex) in
                owner.indexLabel.text = "\(currentImageIndex + 1)"
            }
            .disposed(by: self.disposeBag)
        
        self.viewModel.stateDriver
            .map { $0.imageCount }
            .distinctUntilChanged()
            .drive(with: self) { (owner, imageCount) in
                owner.countLabel.text = "\(imageCount)"
            }
            .disposed(by: self.disposeBag)
        
        self.viewModel.stateDriver
            .map { $0.navigation }
            .distinctUntilChanged()
            .compactMap { $0 }
            .drive(with: self) { (owner, navigation) in
                owner.viewModel.clearNavigation()
                switch navigation {
                case .pop:
                    owner.navigationController?.popViewController(animated: true)
                case .dismiss:
                    owner.dismiss(animated: true, completion: nil)
                case let .cropper(imageData, croppedArea, orientation):
                    guard let viewController = UIStoryboard(name: "ImageCropper", bundle: .main).instantiateInitialViewController() as? ImageCropperViewController else {
                        return
                    }
                    viewController.modalTransitionStyle = .crossDissolve
                    viewController.modalPresentationStyle = .fullScreen
                    viewController.setup(imageData: imageData, croppedArea: croppedArea, orientation: orientation) { (imageData, croppedArea) in
                        owner.viewModel.receiveCroppedImage(data: imageData, croppedArea: croppedArea)
                    }
                    owner.present(viewController, animated: true, completion: nil)
                }
            }
            .disposed(by: self.disposeBag)
    }
}
