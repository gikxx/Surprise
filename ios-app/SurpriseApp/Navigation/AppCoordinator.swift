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
    private var isShowingAuthFlow = false
    
    // MARK: - Init
    // Dependency Injection: передаем окно из SceneDelegate.
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionExpired),
            name: .authSessionExpired,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        
        showAuthFlow(showOnboardingOnFinish: true)
    }
    
    // MARK: - Private Methods
    private func showAuthFlow(showOnboardingOnFinish: Bool) {
        isShowingAuthFlow = true
        childCoordinators.removeAll()
        
        let authCoordinator = AuthCoordinator(navigationController: navigationController)
        
        authCoordinator.onFinish = { [weak self] in
            guard let self = self else { return }
            self.childCoordinators.removeAll()
            self.isShowingAuthFlow = false
            
            if showOnboardingOnFinish {
                self.showOnboardingFlow()
            } else {
                self.showMainFlow()
            }
        }
        
        childCoordinators.append(authCoordinator)
        authCoordinator.start()
    }
    
    private func showOnboardingFlow() {
        isShowingAuthFlow = false
        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController)
        
        onboardingCoordinator.onFinish = { [weak self] in
            self?.childCoordinators.removeAll()
            self?.showMainFlow()
        }
        
        childCoordinators.append(onboardingCoordinator)
        onboardingCoordinator.start()
    }
    
    private func showMainFlow() {
        isShowingAuthFlow = false
        childCoordinators.removeAll()
        
        if !UserDefaults.standard.bool(forKey: "hasSentMainScreenAnalytics") {
            AnalyticsService.shared.logMainScreen()
            UserDefaults.standard.set(true, forKey: "hasSentMainScreenAnalytics")
        }
        
        let mainCoordinator = MainCoordinator(navigationController: navigationController)
        childCoordinators.append(mainCoordinator)
        mainCoordinator.start()
    }
    
    @objc private func handleSessionExpired() {
        guard !isShowingAuthFlow else { return }
        AuthManager.shared.logout()
        showAuthFlow(showOnboardingOnFinish: false)
    }
}
