import Foundation

// MARK: - Gift Model
struct Gift: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let price: Int
    let imageURL: String
    let storeName: String?
    let storeURL: String?
    let createdAt: Date
    let categories: [String]
    
    var isFavorite: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, price, imageURL, storeName, storeURL, createdAt, categories
    }
}
