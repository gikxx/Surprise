import UIKit

// MARK: - MainCoordinator
final class MainCoordinator: Coordinator {
    
    // MARK: - Properties
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private let tabBarController: UITabBarController
    private let tapBar = TapBar()

    private lazy var networkService = NetworkService()
    private lazy var authManager = AuthManager.shared
    private lazy var favoritesService = FavoritesService(
        networkService: networkService,
        authManager: authManager
    )

    private lazy var coreDataStack = CoreDataStack.shared
    private lazy var localDataSource = CoreDataGiftLocalDataSource()
    private lazy var remoteDataSource = GiftRemoteDataSource()
    private lazy var repository = GiftRepository(
        local: localDataSource,
        remote: remoteDataSource
    )
    
    private var didStartFavoritesFlow = false
    private var didStartProfileFlow = false

    private var favoritesNavigationController: UINavigationController?
    private var profileNavigationController: UINavigationController?

    // MARK: - Init
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.tabBarController = UITabBarController()
    }
    
    // MARK: - Start
    func start() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideTapBar),
            name: .tapBarShouldHide,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showTapBar),
            name: .tapBarShouldShow,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openFeedTab),
            name: .openFeedTab,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAccountDeleted),
            name: .accountDeleted,
            object: nil
        )
        setupTabBarAppearance()

        let feedFlow = createFeedFlow()
        let favoritesPlaceholder = SwipeNavigationController()
        let profilePlaceholder = SwipeNavigationController()
        favoritesNavigationController = favoritesPlaceholder
        profileNavigationController = profilePlaceholder

        tabBarController.viewControllers = [feedFlow, favoritesPlaceholder, profilePlaceholder]

        setupTapBar()

        navigationController.setNavigationBarHidden(true, animated: false)

        navigationController.pushViewController(tabBarController, animated: false)
    }
    
    // MARK: - Flow Creators
    
    private func createFeedFlow() -> UINavigationController {
        let nav = SwipeNavigationController()
        
        let coordinator = FeedCoordinator(
            navigationController: nav,
            repository: repository,
            favoritesService: favoritesService
        )
        childCoordinators.append(coordinator)
        coordinator.start()
        return nav
    }
    
    /// Лениво инициализирует Favorites при первом тапе на таб.
    private func startFavoritesFlowIfNeeded() {
        guard !didStartFavoritesFlow,
              let nav = favoritesNavigationController else { return }
        didStartFavoritesFlow = true

        let coordinator = FavoritesCoordinator(
            navigationController: nav,
            repository: repository,
            favoritesService: favoritesService
        )
        childCoordinators.append(coordinator)
        coordinator.start()
    }

    /// Лениво инициализирует Profile при первом тапе на таб.
    private func startProfileFlowIfNeeded() {
        guard !didStartProfileFlow,
              let nav = profileNavigationController else { return }
        didStartProfileFlow = true

        let coordinator = ProfileCoordinator(navigationController: nav)
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    // MARK: - Private Methods
        
    private func setupTapBar() {
        tabBarController.view.addSubview(tapBar)
        tapBar.translatesAutoresizingMaskIntoConstraints = false
        
        tapBar.onTabSelected = { [weak self] index in
            guard let self else { return }
            switch index {
            case 1: self.startFavoritesFlowIfNeeded()
            case 2: self.startProfileFlowIfNeeded()
            default: break
            }
            self.tabBarController.selectedIndex = index
        }

        tapBar.onTabReselected = { [weak self] index in
            guard let self else { return }
            let vcs = self.tabBarController.viewControllers
            switch index {
            case 0:
                // Лента: если не в корне — возврат к корню, иначе скролл наверх
                if let nav = vcs?[0] as? UINavigationController, nav.viewControllers.count > 1 {
                    nav.popToRootViewController(animated: true)
                } else {
                    NotificationCenter.default.post(name: .scrollFeedToTop, object: nil)
                }
            case 1:
                // Избранное: скролл наверх
                NotificationCenter.default.post(name: .scrollFavoritesToTop, object: nil)
            case 2:
                // Профиль: возврат к корню (если зашёл в настройки и т.п.)
                if let nav = vcs?[2] as? UINavigationController {
                    nav.popToRootViewController(animated: true)
                }
            default: break
            }
        }
        
        NSLayoutConstraint.activate([
            tapBar.leadingAnchor.constraint(equalTo: tabBarController.view.leadingAnchor),
            tapBar.trailingAnchor.constraint(equalTo: tabBarController.view.trailingAnchor),
            tapBar.bottomAnchor.constraint(equalTo: tabBarController.view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            tapBar.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        tapBar.updateAppearance(selectedIndex: 0)
    }
    
    private func setupTabBarAppearance() {
        tabBarController.tabBar.isHidden = true
    }

    @objc private func openFeedTab() {
        tabBarController.selectedIndex = 0
        tapBar.updateAppearance(selectedIndex: 0)
    }

    @objc private func hideTapBar() {
        UIView.animate(withDuration: 0.2) { self.tapBar.alpha = 0 }
    }

    @objc private func showTapBar() {
        UIView.animate(withDuration: 0.2) { self.tapBar.alpha = 1 }
    }

    @objc private func handleAccountDeleted() {
        childCoordinators.removeAll()
        navigationController.setViewControllers([], animated: false)
        NotificationCenter.default.post(name: .authSessionExpired, object: nil)
    }
}
