import UIKit

final class OnboardingPageViewController: UIViewController {
    
    // MARK: - Properties
    private let pageView = OnboardingPageView()
    private let model: OnboardingPageModel
    
    // MARK: - Init
    init(model: OnboardingPageModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        view = pageView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageView.configure(with: model)
    }
}
