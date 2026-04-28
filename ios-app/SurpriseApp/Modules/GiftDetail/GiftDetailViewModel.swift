import Foundation

protocol GiftDetailViewModelProtocol: AnyObject {
    var gift: Gift { get }
    var isFavorite: Bool { get }
    
    func toggleFavorite()
}

final class GiftDetailViewModel: GiftDetailViewModelProtocol {
    
    private(set) var gift: Gift
    private let favoritesService: FavoritesServiceProtocol
    
    var isFavorite: Bool {
        favoritesService.isFavorite(id: gift.id)
    }
    
    var onStateChanged: (() -> Void)?
    
    init(gift: Gift, favoritesService: FavoritesServiceProtocol) {
        self.gift = gift
        self.favoritesService = favoritesService
    }
    
    func toggleFavorite() {
        Task {
            do {
                try await favoritesService.toggleFavorite(id: gift.id)
                await MainActor.run {
                    let isNowFavorite = favoritesService.isFavorite(id: gift.id)
                    gift.isFavorite = isNowFavorite
                    Toast.show(
                        isNowFavorite
                            ? "Подарок добавлен в избранное"
                            : "Подарок убран из избранного"
                    )
                    onStateChanged?()
                }
            } catch {
                await MainActor.run {
                    Toast.show("Не удалось обновить избранное")
                    #if DEBUG
                    print("Failed to toggle favorite: \(error)")
                    #endif
                }
            }
        }
    }
}
