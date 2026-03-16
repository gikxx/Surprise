import Foundation

protocol GiftRepositoryProtocol {
    func getAllGifts() async throws -> [Gift]
    func getRecommendedGifts() async throws -> [Gift]
    func getByCategory(_ category: String) async throws -> [Gift]
    func search(query: String) async throws -> [Gift]
    func getCategories() async throws -> [String]
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
        return try await localDataSource.fetchGifts()
    }
    
    // MARK: - Recommended
    
    func getRecommendedGifts() async throws -> [Gift] {
        let gifts = try await getAllGifts()
        
        return gifts.sorted {
            $0.createdAt > $1.createdAt
        }
    }
    
    // MARK: - By Category
    
    func getByCategory(_ category: String) async throws -> [Gift] {
        let gifts = try await getAllGifts()
        return gifts.filter { $0.categories.contains(category) }
    }
    
    // MARK: - Search
    
    func search(query: String) async throws -> [Gift] {
        try await localDataSource.search(query: query)
    }
    
    // MARK: - Categories
    
    func getCategories() async throws -> [String] {
        try await localDataSource.fetchCategories()
    }
}
