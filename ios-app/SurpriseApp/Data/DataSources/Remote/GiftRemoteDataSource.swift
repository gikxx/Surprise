import Foundation

final class GiftRemoteDataSource: GiftRemoteDataSourceProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchAll(page: Int, perPage: Int) async throws -> [Gift] {
        let endpoint = Endpoint(
            path: "/gifts",
            method: .get,
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage))
            ]
        )
        let response: GiftListResponseDTO = try await networkService.request(endpoint)
        return response.gifts.map { $0.toDomain() }
    }

    func fetchRecommended(page: Int, perPage: Int) async throws -> [Gift] {
        let endpoint = Endpoint(
            path: "/gifts/recommended",
            method: .get,
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage))
            ]
        )
        let response: GiftListResponseDTO = try await networkService.request(endpoint)
        return response.gifts.map { $0.toDomain() }
    }

    func search(query: String, page: Int, perPage: Int) async throws -> [Gift] {
        let endpoint = Endpoint(
            path: "/gifts/search",
            method: .get,
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage))
            ]
        )
        let response: GiftListResponseDTO = try await networkService.request(endpoint)
        return response.gifts.map { $0.toDomain() }
    }

    func fetchByCategory(_ category: String, page: Int, perPage: Int) async throws -> [Gift] {
        let endpoint = Endpoint(
            path: "/gifts",
            method: .get,
            queryItems: [
                URLQueryItem(name: "category", value: category),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage))
            ]
        )
        let response: GiftListResponseDTO = try await networkService.request(endpoint)
        return response.gifts.map { $0.toDomain() }
    }

    func fetchCategories() async throws -> [String] {
        let gifts = try await fetchAll(page: 1, perPage: 500)
        let categories = Set(gifts.flatMap(\.categories))
        return categories.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}
