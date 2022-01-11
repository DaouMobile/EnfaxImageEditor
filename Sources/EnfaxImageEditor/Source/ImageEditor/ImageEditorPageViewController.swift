import UIKit

class ImageEditorPageViewController: UIPageViewController {
    private(set) var viewModel: ImageEditorViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.dataSource = self
        
        let currentImageIndex = self.viewModel.state.currentImageIndex
        let viewController: ImageEditorContentViewController = self.makeContentViewController(index: currentImageIndex)
        self.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)
    }
    
    func setup(viewModel: ImageEditorViewModel) {
        self.viewModel = viewModel
    }
    
    private func makeContentViewController(index: Int) -> ImageEditorContentViewController {
        let bundle: Bundle = .init(for: Self.self)
        let viewController = UIStoryboard(
            name: "ImageEditor",
            bundle: bundle
        ).instantiateViewController(
            withIdentifier: "ImageEditorContentViewController"
        ) as! ImageEditorContentViewController
        viewController.setup(viewModel: self.viewModel, index: index)
        return viewController
    }
}

extension ImageEditorPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let index = (pageViewController.viewControllers?.first as? ImageEditorContentViewController)?.index else {
            return
        }
        self.viewModel.setIndex(index)
    }
}

extension ImageEditorPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = (viewController as? ImageEditorContentViewController)?.index else {
            return nil
        }
        self.viewModel.setIndex(index)
        let indexBefore = index - 1
        guard indexBefore >= 0 else {
            return nil
        }
        return self.makeContentViewController(index: indexBefore)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = (viewController as? ImageEditorContentViewController)?.index else {
            return nil
        }
        self.viewModel.setIndex(index)
        let indexAfter = index + 1
        guard indexAfter < self.viewModel.state.imageCount else {
            return nil
        }
        return self.makeContentViewController(index: indexAfter)
    }
}
