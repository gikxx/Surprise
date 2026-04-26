import Foundation
import CoreData 

// MARK: - FavoritesServiceProtocol
protocol FavoritesServiceProtocol {
    func toggleFavorite(id: Int) async throws
    func isFavorite(id: Int) -> Bool
    func getFavoriteIds() -> Set<Int>
    func syncFromServer() async throws
    func fetchFavoriteGifts() async throws -> [Gift]
}

// MARK: - FavoritesService
final class FavoritesService: FavoritesServiceProtocol {
    private let key = "favorite_ids"
    private var favoriteIds: Set<Int> = []
    private let networkService: NetworkServiceProtocol
    private let authManager: AuthManager

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        authManager: AuthManager = .shared
    ) {
        self.networkService = networkService
        self.authManager = authManager
        load()
    }

    // MARK: - Public

    func syncFromServer() async throws {
        guard let token = authManager.token, !token.isEmpty else {
            return
        }

        let endpoint = Endpoint(path: "/favorites", method: .get)
        do {
            let response: [FavoriteDTO] = try await networkService.request(endpoint)
            let serverIds = Set(response.map { $0.id })
            await MainActor.run {
                self.favoriteIds = serverIds
                self.save()
            }
        } catch {
            AnalyticsService.shared.logCriticalError(scenario: "sync_favorites", error: error)
            throw error
        }
    }

    func toggleFavorite(id: Int) async throws {
        guard let token = authManager.token, !token.isEmpty else {
            await MainActor.run {
                if favoriteIds.contains(id) {
                    AnalyticsService.shared.logRemoveFromFavorites(giftId: id)
                    favoriteIds.remove(id)
                } else {
                    AnalyticsService.shared.logAddToFavorites(giftId: id)
                    favoriteIds.insert(id)
                }
                save()
            }
            return
        }
        
        let endpoint = Endpoint(path: "/favorites/\(id)/toggle", method: .post)
        do {
            let _: EmptyResponse = try await networkService.request(endpoint)
            await MainActor.run {
                if favoriteIds.contains(id) {
                    AnalyticsService.shared.logRemoveFromFavorites(giftId: id)
                    favoriteIds.remove(id)
                } else {
                    AnalyticsService.shared.logAddToFavorites(giftId: id)
                    favoriteIds.insert(id)
                }
                save()
            }
        } catch {
            AnalyticsService.shared.logCriticalError(scenario: "toggle_favorite", error: error, parameters: ["gift_id": id])
            throw error
        }
    }   
    
    func fetchFavoriteGifts() async throws -> [Gift] {
        guard let token = authManager.token, !token.isEmpty else {
            return []
        }
        let endpoint = Endpoint(path: "/favorites", method: .get)
        let dtos: [GiftReadDTO] = try await networkService.request(endpoint)
        return dtos.map { $0.toDomain() }
    }

    func isFavorite(id: Int) -> Bool {
        favoriteIds.contains(id)
    }

    func getFavoriteIds() -> Set<Int> {
        favoriteIds
    }

    // MARK: - Private

    private func save() {
        UserDefaults.standard.set(Array(favoriteIds), forKey: key)
    }

    private func load() {
        let ids = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        favoriteIds = Set(ids)
    }
}

private struct FavoriteDTO: Decodable {
    let id: Int
}

private struct EmptyResponse: Decodable {}
