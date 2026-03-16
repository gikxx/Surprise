import Foundation
import CoreData 

// MARK: - FavoritesServiceProtocol
protocol FavoritesServiceProtocol {
    func toggleFavorite(id: Int)
    func isFavorite(id: Int) -> Bool
    func getFavoriteIds() -> Set<Int>
}

// MARK: - FavoritesService (локальное хранение)
/// Локальная реализация избранного на основе UserDefaults
final class FavoritesService: FavoritesServiceProtocol {
    
    private let key = "favorite_ids"
    private var favoriteIds: Set<Int> = []
    
    init() {
        load()
    }
    
    func toggleFavorite(id: Int) {
        if favoriteIds.contains(id) {
            favoriteIds.remove(id)
        } else {
            favoriteIds.insert(id)
        }
        save()
    }
    
    func isFavorite(id: Int) -> Bool {
        favoriteIds.contains(id)
    }
    
    func getFavoriteIds() -> Set<Int> {
        favoriteIds
    }
    
    private func save() {
        UserDefaults.standard.set(Array(favoriteIds), forKey: key)
    }
    
    private func load() {
        let ids = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        favoriteIds = Set(ids)
    }
}
