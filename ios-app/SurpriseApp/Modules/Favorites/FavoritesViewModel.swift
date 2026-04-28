import Foundation

protocol FavoritesViewModelProtocol: AnyObject {
    var items: [Gift] { get }
    var isEmpty: Bool { get }
    var onStateChanged: (() -> Void)? { get set }
    /// Вызывается когда подарок удалён из UI (до истечения таймера).
    /// Параметр — giftId, чтобы ViewController мог показать undo-баннер.
    var onRemovalPending: ((Int) -> Void)? { get set }

    func loadFavorites()
    func removeFromFavorites(_ giftId: Int)
    func undoRemoval(of giftId: Int)
}

// MARK: - Pending removal

private struct PendingRemoval {
    let gift: Gift
    let originalIndex: Int
    let workItem: DispatchWorkItem
}

// MARK: - FavoritesViewModel

final class FavoritesViewModel: FavoritesViewModelProtocol {

    private let favoritesService: FavoritesServiceProtocol
    private let repository: GiftRepositoryProtocol

    private(set) var items: [Gift] = []
    private(set) var isEmpty: Bool = true

    var onStateChanged: (() -> Void)?
    var onRemovalPending: ((Int) -> Void)?

    private var pendingRemovals: [Int: PendingRemoval] = [:]

    private let undoDelay: TimeInterval = 5

    init(
        repository: GiftRepositoryProtocol,
        favoritesService: FavoritesServiceProtocol = FavoritesService()
    ) {
        self.repository = repository
        self.favoritesService = favoritesService
    }

    // MARK: - Public

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
        guard let index = items.firstIndex(where: { $0.id == giftId }) else { return }
        let gift = items[index]

        items.remove(at: index)
        isEmpty = items.isEmpty
        onStateChanged?()

        onRemovalPending?(giftId)

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            Task {
                do {
                    try await self.favoritesService.toggleFavorite(id: giftId)
                } catch {
                    // Сетевая ошибка — возвращаем подарок в список
                    await MainActor.run {
                        if let pending = self.pendingRemovals[giftId] {
                            self.items.insert(
                                pending.gift,
                                at: min(pending.originalIndex, self.items.count)
                            )
                            self.isEmpty = false
                            self.onStateChanged?()
                            Toast.show("Не удалось удалить из избранного")
                        }
                    }
                }
                await MainActor.run {
                    self.pendingRemovals.removeValue(forKey: giftId)
                }
            }
        }

        pendingRemovals[giftId] = PendingRemoval(
            gift: gift,
            originalIndex: index,
            workItem: workItem
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + undoDelay, execute: workItem)
    }

    func undoRemoval(of giftId: Int) {
        guard let pending = pendingRemovals[giftId] else { return }

        pending.workItem.cancel()
        pendingRemovals.removeValue(forKey: giftId)

        let insertAt = min(pending.originalIndex, items.count)
        items.insert(pending.gift, at: insertAt)
        isEmpty = false
        onStateChanged?()
    }
}
