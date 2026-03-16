import Foundation

// MARK: - User Model
struct User: Codable {
    let id: Int
    let name: String
    let email: String?
    let phone: String?
    let isGuest: Bool?
}

// MARK: - AuthResponse Model
struct AuthResponse: Codable {
    let user: User
    let token: String
}
