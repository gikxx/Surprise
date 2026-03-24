//
//  AppCoordinator.swift
//  SurpriseApp
//
//  Created by Карина Гетманова on 1/27/26.
//

import UIKit

final class AppCoordinator: Coordinator {
    
    // MARK: - Properties
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private let window: UIWindow
    
    // MARK: - Init
    // Dependency Injection: передаем окно из SceneDelegate.
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
    }
    
    // MARK: - Public Methods
    func start() {
        // Устанавливаем наш NavigationController как корневой для окна
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        if AuthManager.shared.isLoggedIn {
            showMainFlow()
            return
        }
        
        showAuthFlow()
    }
    
    // MARK: - Private Methods
    private func showAuthFlow() {
        let authCoordinator = AuthCoordinator(navigationController: navigationController)
        
        authCoordinator.onFinish = { [weak self] in
            self?.childCoordinators.removeAll()
            self?.showOnboardingFlow()
        }
        
        childCoordinators.append(authCoordinator)
        authCoordinator.start()
    }
    
    private func showOnboardingFlow() {
        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController)
        
        onboardingCoordinator.onFinish = { [weak self] in
            self?.childCoordinators.removeAll()
            self?.showMainFlow()
        }
        
        childCoordinators.append(onboardingCoordinator)
        onboardingCoordinator.start()
    }
    
    private func showMainFlow() {
        let mainCoordinator = MainCoordinator(navigationController: navigationController)
        childCoordinators.append(mainCoordinator)
        mainCoordinator.start()
    }
}
