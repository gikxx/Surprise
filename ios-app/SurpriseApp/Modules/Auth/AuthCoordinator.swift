import UIKit

final class AuthCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    // Это событие мы вызовем, когда пользователь успешно зарегистрируется
    var onFinish: (() -> Void)?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        showWelcome()
    }
    
    private func showWelcome() {
        let vc = WelcomeViewController()
        vc.onRegister = { [weak self] in self?.showRegistration() }
        vc.onLogin = { [weak self] in self?.showLogin() }
        vc.onSkip = { [weak self] in
            // Запускаем гостевой режим и уходим в основной поток
            AuthManager.shared.setGuestSession()
            self?.onFinish?()
        } // Уходим на ленту
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showLogin() {
        let viewModel = AuthViewModel(authService: AuthService())
        let vc = LoginViewController(viewModel: viewModel, shouldShowBackButton: true)
        vc.onLoginSuccess = { [weak self] in
            self?.onFinish?()
        }
        vc.onNoAccount = { [weak self] in
            self?.showRegistrationFromLogin()
        }
        vc.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(vc, animated: true)
    }

    private func showRegistration() {
        let viewModel = AuthViewModel(authService: AuthService())
        let vc = RegistrationViewController(viewModel: viewModel, shouldShowBackButton: true)
        vc.onContinue = { [weak self] in self?.showSuccess() }
        vc.onSkip = { [weak self] in
            AuthManager.shared.setGuestSession()
            self?.onFinish?()
        }
        vc.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(vc, animated: true)
    }

    // Регистрация из экрана логина — показываем кнопку назад
    private func showRegistrationFromLogin() {
        let viewModel = AuthViewModel(authService: AuthService())
        let vc = RegistrationViewController(viewModel: viewModel, shouldShowBackButton: true)
        vc.onContinue = { [weak self] in self?.showSuccess() }
        vc.onSkip = { [weak self] in
            AuthManager.shared.setGuestSession()
            self?.onFinish?()
        }
        vc.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(vc, animated: true)
    }

    private func showSuccess() {
        let successVC = SuccessViewController()
            
        // Делаем так, чтобы через 2.5 секунды экран сам закрылся и пустил нас в ленту
        navigationController.pushViewController(successVC, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.onFinish?() // Сообщаем AppCoordinator, что всё готово
        }
    }
    
    @objc private func didRegister() {
        // Когда кнопка нажата, мы говорим AppCoordinator: "Мы закончили!"
        onFinish?()
    }
}
