import Foundation

protocol GiftRemoteDataSourceProtocol {
    func fetchAll(page: Int, perPage: Int) async throws -> [Gift]
    func fetchRecommended(page: Int, perPage: Int) async throws -> [Gift]
    /// Как fetchRecommended, но возвращает полный ответ с пагинацией.
    func fetchRecommendedPage(page: Int, perPage: Int) async throws -> GiftPage
    func search(query: String, page: Int, perPage: Int) async throws -> [Gift]
    func fetchByCategory(id: Int, page: Int, perPage: Int) async throws -> [Gift]
    func fetchCategories() async throws -> [Category]
}
