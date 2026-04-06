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
        return response.gifts.map { $0.toDomainGift() }
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
        return response.gifts.map { $0.toDomainGift() }
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
        return response.gifts.map { $0.toDomainGift() }
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
        return response.gifts.map { $0.toDomainGift() }
    }

    func fetchCategories() async throws -> [String] {
        let gifts = try await fetchAll(page: 1, perPage: 500)
        let categories = Set(gifts.flatMap(\.categories))
        return categories.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

private struct GiftListResponseDTO: Decodable {
    let gifts: [GiftReadDTO]
    let total: Int
    let page: Int
    let perPage: Int

    enum CodingKeys: String, CodingKey {
        case gifts, total, page
        case perPage = "per_page"
    }
}

private struct GiftReadDTO: Decodable {
    let id: Int
    let name: String
    let description: String?
    let price: Int
    let categories: [String]
    let imageURL: String
    let galleryImageURLs: [String]?
    let storeName: String?
    let storeURL: String?
    let createdAt: Date
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description, price, categories
        case imageURL = "image_url"
        case galleryImageURLs = "gallery_image_urls"
        case storeName = "store_name"
        case storeURL = "store_url"
        case createdAt = "created_at"
        case isFavorite = "is_favorite"
    }

    func toDomainGift() -> Gift {
        Gift(
            id: id,
            name: name,
            description: description,
            price: price,
            imageURL: imageURL,
            storeName: storeName,
            storeURL: storeURL,
            createdAt: createdAt,
            categories: categories,
            isFavorite: isFavorite
        )
    }
}

