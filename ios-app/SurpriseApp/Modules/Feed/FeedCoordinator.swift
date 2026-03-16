import UIKit

protocol FeedCoordinating: AnyObject {
    func showGiftDetail(_ gift: Gift)
}

final class FeedCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private let repository: GiftRepositoryProtocol
    private let favoritesService: FavoritesServiceProtocol
    
    init(
        navigationController: UINavigationController,
        repository: GiftRepositoryProtocol,
        favoritesService: FavoritesServiceProtocol
    ) {
        self.navigationController = navigationController
        self.repository = repository
        self.favoritesService = favoritesService
    }
    
    func start() {
        let viewModel = FeedViewModel(
            repository: repository,
            favoritesService: favoritesService
        )
        
        let feedVC = FeedViewController(viewModel: viewModel)
        
        feedVC.onGiftSelected = { [weak self] gift in
            self?.showGiftDetail(gift)
        }
        
        navigationController.viewControllers = [feedVC]
    }
    
    private func showGiftDetail(_ gift: Gift) {
        let detailCoordinator = GiftDetailCoordinator(
            navigationController: navigationController,
            gift: gift,
            favoritesService: favoritesService
        )
        childCoordinators.append(detailCoordinator)
        detailCoordinator.start()
    }
}
