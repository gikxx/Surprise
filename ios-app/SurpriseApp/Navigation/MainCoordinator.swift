import UIKit

// MARK: - MainCoordinator
final class MainCoordinator: Coordinator {
    
    // MARK: - Properties
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private let tabBarController: UITabBarController
    private let tapBar = TapBar()
    
    private let favoritesService = FavoritesService()
    
    private lazy var coreDataStack = CoreDataStack.shared
    private lazy var localDataSource = CoreDataGiftLocalDataSource()
    private lazy var repository = GiftRepository(
        local: localDataSource,
        remote: nil
    )
    
    // MARK: - Init
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.tabBarController = UITabBarController()
    }
    
    // MARK: - Start
    func start() {
        setupTabBarAppearance()
        
        let feedFlow = createFeedFlow()
        let favoritesFlow = createFavoritesFlow()
        let profileFlow = createProfileFlow()
        
        tabBarController.viewControllers = [feedFlow, favoritesFlow, profileFlow]
        
        setupTapBar()
        
        navigationController.setNavigationBarHidden(true, animated: false)
        
        navigationController.pushViewController(tabBarController, animated: false)
    }
    
    // MARK: - Flow Creators
    
    private func createFeedFlow() -> UINavigationController {
        let nav = UINavigationController()
        
        let coordinator = FeedCoordinator(
            navigationController: nav,
            repository: repository,
            favoritesService: favoritesService
        )
        childCoordinators.append(coordinator)
        coordinator.start()
        return nav
    }
    
    private func createFavoritesFlow() -> UINavigationController {
        let nav = UINavigationController()
        
        let coordinator = FavoritesCoordinator(
            navigationController: nav,
            repository: repository,
            favoritesService: favoritesService)
        childCoordinators.append(coordinator)
        coordinator.start()
        return nav
    }
    
    private func createProfileFlow() -> UINavigationController {
        let nav = UINavigationController()
        let vc = ProfileViewController() // TODO: Щас заглушка
        nav.viewControllers = [vc]
        
        
        return nav
    }
    
    // MARK: - Private Methods
        
    private func setupTapBar() {
        tabBarController.view.addSubview(tapBar)
        tapBar.translatesAutoresizingMaskIntoConstraints = false
        
        tapBar.onTabSelected = { [weak self] index in
            self?.tabBarController.selectedIndex = index
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
}
