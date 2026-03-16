import Foundation

protocol FavoritesViewModelProtocol: AnyObject {
    var items: [Gift] { get }
    var isEmpty: Bool { get }
    var onStateChanged: (() -> Void)? { get set }
    
    func loadFavorites()
    func removeFromFavorites(_ giftId: Int)
}

final class FavoritesViewModel: FavoritesViewModelProtocol {

    private let favoritesService: FavoritesServiceProtocol
    private let repository: GiftRepositoryProtocol
    
    private(set) var items: [Gift] = []
    private(set) var isEmpty: Bool = true
    
    var onStateChanged: (() -> Void)?
    
    init(
        repository: GiftRepositoryProtocol,
        favoritesService: FavoritesServiceProtocol = FavoritesService()
    ) {
        self.repository = repository
        self.favoritesService = favoritesService
    }
    
    func loadFavorites() {
        Task {
            do {
                let allGifts = try await repository.getAllGifts()
                let favoriteIds = favoritesService.getFavoriteIds()
                let favorites = allGifts.filter { favoriteIds.contains($0.id) }
                    .map { gift -> Gift in
                        var copy = gift
                        copy.isFavorite = true
                        return copy
                    }
                
                await MainActor.run {
                    self.items = favorites
                    self.isEmpty = favorites.isEmpty
                    self.onStateChanged?()
                }
            } catch {
                print("❌ Failed to load favorites: \(error)")
            }
        }
    }
    
    func removeFromFavorites(_ giftId: Int) {
        favoritesService.toggleFavorite(id: giftId)
        items.removeAll { $0.id == giftId }
        isEmpty = items.isEmpty
        onStateChanged?()
    }
}
