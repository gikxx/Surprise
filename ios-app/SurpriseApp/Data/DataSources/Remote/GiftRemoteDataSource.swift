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

    func fetchByCategory(id: Int, page: Int, perPage: Int) async throws -> [Gift] {
        let endpoint = Endpoint(
            path: "/gifts",
            method: .get,
            queryItems: [
                URLQueryItem(name: "category_id", value: String(id)),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage))
            ]
        )
        let response: GiftListResponseDTO = try await networkService.request(endpoint)
        return response.gifts.map { $0.toDomain() }
    }

    func fetchCategories() async throws -> [Category] {
        // Раньше вытягивали все подарки и собирали Set уникальных строк —
        // теперь у бэка есть отдельный endpoint, и категории приходят
        // объектами {id, name}.
        let endpoint = Endpoint(path: "/categories", method: .get)
        let dtos: [CategoryReadDTO] = try await networkService.request(endpoint)
        return dtos.map { $0.toDomain() }
    }
}
