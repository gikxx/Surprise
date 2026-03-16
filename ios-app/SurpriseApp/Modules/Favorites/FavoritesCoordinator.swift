import UIKit
import SafariServices

final class FavoritesCoordinator: Coordinator {
    
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
        let viewModel = FavoritesViewModel(
            repository: repository,
            favoritesService: favoritesService,
        )
        let favoritesVC = FavoritesViewController(viewModel: viewModel)
        
        favoritesVC.onGiftSelected = { [weak self] gift in
            self?.showGiftDetail(gift)
        }
        
        favoritesVC.onBuyTapped = { [weak self] gift in
            self?.openStore(for: gift)
        }
        
        navigationController.viewControllers = [favoritesVC]
        
        loadFavorites(into: viewModel)
    }
    
    private func loadFavorites(into viewModel: FavoritesViewModel) {
        Task {
            do {
                await MainActor.run {
                    viewModel.loadFavorites()
                }
            } catch {
                print("Failed to load gifts:", error)
            }
        }
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
    
    private func openStore(for gift: Gift) {
        guard let urlString = gift.storeURL,
              let url = URL(string: urlString) else { return }
        
        let safari = SFSafariViewController(url: url)
        navigationController.present(safari, animated: true)
    }
}
