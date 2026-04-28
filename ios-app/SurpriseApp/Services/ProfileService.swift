import Foundation

protocol ProfileServiceProtocol {
    func fetchProfile() async throws -> User
    func updateProfile(name: String?, email: String?, phone: String?) async throws -> User
    func updateAvatar(url: String) async throws -> User
    func deleteAccount() async throws
}

final class ProfileService: ProfileServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchProfile() async throws -> User {
        let endpoint = Endpoint(path: "/users/me", method: .get)
        return try await networkService.request(endpoint)
    }
    
    func updateProfile(name: String?, email: String?, phone: String?) async throws -> User {
        if let name = name {
                try ValidationService.shared.validateName(name)
            }
        try ValidationService.shared.validateEmail(email)
        try ValidationService.shared.validatePhone(phone)
        
        var body: [String: Any] = [:]
        if let name = name, !name.isEmpty {
            body["name"] = name
        }
        if let email = email, !email.isEmpty {
            body["email"] = email
        }
        if let phone = phone, !phone.isEmpty {
            body["phone"] = phone
        }
        
        let endpoint = Endpoint(path: "/users/me", method: .put, bodyParameters: body)
        return try await networkService.request(endpoint)
    }
    
    func updateAvatar(url: String) async throws -> User {
        let endpoint = Endpoint(
            path: "/users/me",
            method: .put,
            bodyParameters: ["avatar_url": url]
        )
        return try await networkService.request(endpoint)
    }

    func deleteAccount() async throws {
        let endpoint = Endpoint(path: "/auth/me", method: .delete)
        try await networkService.requestVoid(endpoint)
    }
}
