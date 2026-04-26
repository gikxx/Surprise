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
                let favoriteGifts = try await favoritesService.fetchFavoriteGifts()
                let resolvedFavorites: [Gift]
                
                if favoriteGifts.isEmpty {
                    let allGifts = try await repository.getAllGifts()
                    let localIds = favoritesService.getFavoriteIds()
                    resolvedFavorites = allGifts.filter { localIds.contains($0.id) }
                } else {
                    resolvedFavorites = favoriteGifts
                }
                
                await MainActor.run {
                    self.items = resolvedFavorites
                    self.isEmpty = resolvedFavorites.isEmpty
                    self.onStateChanged?()
                }
            } catch {
                #if DEBUG
                print("❌ Failed to load favorite gifts: \(error)")
                #endif
            }
        }
    }
    
    func removeFromFavorites(_ giftId: Int) {
        Task {
           do {
               try await favoritesService.toggleFavorite(id: giftId)
               await MainActor.run {
                   self.items.removeAll { $0.id == giftId }
                   self.isEmpty = self.items.isEmpty
                   self.onStateChanged?()
               }
           } catch {
               #if DEBUG
               print("❌ Failed to remove favorite: \(error)")
               #endif
               await MainActor.run {
                   self.onStateChanged?()
               }
           }
       }
    }
}
