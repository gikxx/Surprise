import Foundation

// MARK: - User Model

struct User: Decodable {
    let id: Int
    let name: String
    let email: String?
    let phone: String?
    let isGuest: Bool
    let createdAt: Date?
    var avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, is_guest, created_at, avatar_url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        isGuest = try container.decode(Bool.self, forKey: .is_guest)
        let dateString = try container.decodeIfPresent(String.self, forKey: .created_at)
        createdAt = dateString.flatMap { ISO8601DateFormatter().date(from: $0) }
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatar_url)
    }
    
    init(id: Int, name: String, email: String?, phone: String?, isGuest: Bool, avatarUrl: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.isGuest = isGuest
        self.createdAt = nil
        self.avatarUrl = avatarUrl
    }
}

// MARK: - AuthResponse Model
struct AuthResponse: Decodable {
    let user: User
    let token: String
}
