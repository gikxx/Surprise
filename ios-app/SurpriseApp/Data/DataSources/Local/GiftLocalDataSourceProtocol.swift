import Foundation

protocol GiftLocalDataSourceProtocol {
    func fetchGifts() async throws -> [Gift]
    func search(query: String) async throws -> [Gift]
    func fetchCategories() async throws -> [Category]
}
