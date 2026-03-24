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
        print("📁 [Repository] getAllGifts called")
        if let remoteDataSource {
            do {
                let gifts = try await remoteDataSource.fetchAll(page: 1, perPage: 200)
                print("✅ [Repository] got \(gifts.count) gifts from remote")
                return gifts
            } catch {
                print("⚠️ [Repository] remote failed, falling back to local")
                let gifts = try await localDataSource.fetchGifts()
                print("✅ [Repository] got \(gifts.count) gifts from local")
                return gifts
            }
        }
        let gifts = try await localDataSource.fetchGifts()
        print("✅ [Repository] got \(gifts.count) gifts from local (no remote)")
        return gifts
    }
    
    // MARK: - Recommended
    
    func getRecommendedGifts() async throws -> [Gift] {
        print("⭐️ [Repo] getRecommendedGifts")
        
        if let remoteDataSource {
            print("📡 [Repo] remoteDataSource exists, trying...")
            do {
                let gifts = try await remoteDataSource.fetchRecommended(page: 1, perPage: 50)
                print("✅ [Repo] got \(gifts.count) gifts from remote")
                return gifts
            } catch {
                print("⚠️ [Repo] remote failed: \(error.localizedDescription)")
                print("📦 [Repo] falling back to local")
                let gifts = try await getAllGifts()
                print("✅ [Repo] got \(gifts.count) gifts from local (fallback)")
                return gifts.sorted { $0.createdAt > $1.createdAt }
            }
        }
        
        print("📦 [Repo] no remote, using local")
        let gifts = try await getAllGifts()
        print("✅ [Repo] got \(gifts.count) gifts from local")
        return gifts.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - By Category
    
    func getByCategory(_ category: String) async throws -> [Gift] {
        if let remoteDataSource {
            do {
                return try await remoteDataSource.fetchByCategory(category, page: 1, perPage: 200)
            } catch {
                let gifts = try await getAllGifts()
                return gifts.filter { $0.categories.contains(category) }
            }
        }
        let gifts = try await getAllGifts()
        return gifts.filter { $0.categories.contains(category) }
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
    
    func getCategories() async throws -> [String] {
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
