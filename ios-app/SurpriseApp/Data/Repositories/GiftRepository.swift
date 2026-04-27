import Foundation

protocol GiftRepositoryProtocol {
    func getAllGifts() async throws -> [Gift]
    func getRecommendedGifts() async throws -> [Gift]
    func getByCategory(id: Int) async throws -> [Gift]
    func search(query: String) async throws -> [Gift]
    func getCategories() async throws -> [Category]
}

final class GiftRepository: GiftRepositoryProtocol {

    private let localDataSource: GiftLocalDataSourceProtocol
    private let remoteDataSource: GiftRemoteDataSourceProtocol?

    init(
        local: GiftLocalDataSourceProtocol,
        remote: GiftRemoteDataSourceProtocol? = nil
    ) {
        self.localDataSource = local
        self.remoteDataSource = remote
    }

    // MARK: - All Gifts

    func getAllGifts() async throws -> [Gift] {
        if let remoteDataSource {
            do {
                return try await remoteDataSource.fetchAll(page: 1, perPage: 200)
            } catch {
                return try await localDataSource.fetchGifts()
            }
        }
        return try await localDataSource.fetchGifts()
    }

    // MARK: - Recommended

    func getRecommendedGifts() async throws -> [Gift] {
        if let remoteDataSource {
            do {
                return try await remoteDataSource.fetchRecommended(page: 1, perPage: 50)
            } catch {
                let gifts = try await getAllGifts()
                return gifts.sorted { $0.createdAt > $1.createdAt }
            }
        }

        let gifts = try await getAllGifts()
        return gifts.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - By Category

    func getByCategory(id: Int) async throws -> [Gift] {
        if let remoteDataSource {
            do {
                return try await remoteDataSource.fetchByCategory(id: id, page: 1, perPage: 200)
            } catch {
                let gifts = try await getAllGifts()
                return gifts.filter { gift in
                    gift.categories.contains(where: { $0.id == id })
                }
            }
        }
        let gifts = try await getAllGifts()
        return gifts.filter { gift in
            gift.categories.contains(where: { $0.id == id })
        }
    }

    // MARK: - Search

    func search(query: String) async throws -> [Gift] {
        if let remoteDataSource {
            do {
                return try await remoteDataSource.search(query: query, page: 1, perPage: 200)
            } catch {
                return try await localDataSource.search(query: query)
            }
        }
        return try await localDataSource.search(query: query)
    }

    // MARK: - Categories

    func getCategories() async throws -> [Category] {
        if let remoteDataSource {
            do {
                return try await remoteDataSource.fetchCategories()
            } catch {
                return try await localDataSource.fetchCategories()
            }
        }
        return try await localDataSource.fetchCategories()
    }
}
