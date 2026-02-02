import UIKit

final class OnboardingCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var onFinish: (() -> Void)?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = OnboardingContainerViewController()
        vc.onFinish = { [weak self] in
            self?.showFinalOnboarding()
        }
        navigationController.setViewControllers([vc], animated: true)
    }
    
    private func showFinalOnboarding() {
        let finalVC = FinalOnboardingViewController()
        finalVC.onCompletion = { [weak self] in
            self?.onFinish?()
        }
        navigationController.pushViewController(finalVC, animated: true)
    }
}
