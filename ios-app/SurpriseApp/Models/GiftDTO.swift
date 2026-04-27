import Foundation

// MARK: - CategoryDTO
struct CategoryReadDTO: Decodable {
    let id: Int
    let name: String

    func toDomain() -> Category {
        Category(id: id, name: name)
    }
}

// MARK: - GiftImageDTO
struct GiftImageDTO: Decodable {
    let url: String
    let sortOrder: Int
    let isPrimary: Bool

    enum CodingKeys: String, CodingKey {
        case url
        case sortOrder = "sort_order"
        case isPrimary = "is_primary"
    }

    func toDomain() -> GiftImage {
        GiftImage(url: url, sortOrder: sortOrder, isPrimary: isPrimary)
    }
}

// MARK: - GiftReadDTO
struct GiftReadDTO: Decodable {
    let id: Int
    let name: String
    let description: String?
    let price: Int
    let categories: [CategoryReadDTO]
    let imageURL: String
    let images: [GiftImageDTO]?
    let storeName: String?
    let storeURL: String?
    let createdAt: Date
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description, price, categories, images
        case imageURL = "image_url"
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
            categories: categories.map { $0.toDomain() },
            images: (images ?? []).map { $0.toDomain() },
            isFavorite: isFavorite
        )
    }
}

// MARK: - GiftListResponseDTO
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
