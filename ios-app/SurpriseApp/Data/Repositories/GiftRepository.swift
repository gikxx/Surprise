import Foundation

protocol GiftRepositoryProtocol {
    func getAllGifts() async throws -> [Gift]
    func getRecommendedGifts() async throws -> [Gift]
    /// Постраничная версия — возвращает total, чтобы ViewModel знала,
    /// есть ли ещё страницы.
    func getRecommendedPage(page: Int, perPage: Int) async throws -> GiftPage
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
        try await getRecommendedPage(page: 1, perPage: 20).gifts
    }

    func getRecommendedPage(page: Int, perPage: Int) async throws -> GiftPage {
        if let remoteDataSource {
            do {
                return try await remoteDataSource.fetchRecommendedPage(page: page, perPage: perPage)
            } catch {
                // Фоллбэк на локальные данные — возвращаем одну страницу без пагинации
                let all = try await localDataSource.fetchGifts()
                let sorted = all.sorted { $0.createdAt > $1.createdAt }
                return GiftPage(gifts: sorted, total: sorted.count, page: 1, perPage: sorted.count)
            }
        }

        let all = try await localDataSource.fetchGifts()
        let sorted = all.sorted { $0.createdAt > $1.createdAt }
        return GiftPage(gifts: sorted, total: sorted.count, page: 1, perPage: sorted.count)
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
