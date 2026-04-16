import Foundation

struct GiftReadDTO: Decodable {
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

    func toDomain() -> Gift {
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

struct GiftListResponseDTO: Decodable {
    let gifts: [GiftReadDTO]
    let total: Int
    let page: Int
    let perPage: Int

    enum CodingKeys: String, CodingKey {
        case gifts, total, page
        case perPage = "per_page"
    }
}
