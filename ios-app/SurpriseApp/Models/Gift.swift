import Foundation

// MARK: - ImageType

enum ImageType: String, Equatable {
    case photo       = "photo"
    case transparent = "transparent"
}

// MARK: - Gift Model
struct Gift: Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String?
    let price: Int
    let imageURL: String
    let imageType: ImageType
    let storeName: String?
    let storeURL: String?
    let createdAt: Date
    let categories: [Category]
    let images: [GiftImage]

    var isFavorite: Bool = false
}
