import UIKit
import SafariServices

final class GiftDetailCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private let gift: Gift
    private let favoritesService: FavoritesServiceProtocol
    
    init(
        navigationController: UINavigationController,
        gift: Gift,
        favoritesService: FavoritesServiceProtocol
    ) {
        self.navigationController = navigationController
        self.gift = gift
        self.favoritesService = favoritesService
    }
    
    func start() {
        let viewModel = GiftDetailViewModel(
            gift: gift,
            favoritesService: favoritesService
        )
        
        let detailVC = GiftDetailViewController(viewModel: viewModel)
        
        detailVC.onBuyTapped = { [weak self] in
            self?.openStore()
        }
        
        detailVC.onBackTapped = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        
        navigationController.pushViewController(detailVC, animated: true)
    }
    
    private func openStore() {
        guard let urlString = gift.storeURL,
              let url = URL(string: urlString) else { return }
        
        let safari = SFSafariViewController(url: url)
        navigationController.present(safari, animated: true)
    }
}
