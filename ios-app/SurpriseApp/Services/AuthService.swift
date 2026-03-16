import Foundation

// MARK: - AuthError
enum AuthError: Error {
    case invalidCredentials
    case validationFailed(String)
    case network(NetworkError)
    case unknown
}

// MARK: - AuthServiceProtocol
protocol AuthServiceProtocol {
    /// Регистрация по почте или телефону.
    func register(
        emailOrPhone: String,
        name: String,
        password: String
    ) async throws -> AuthResponse
    
    /// Вход в существующий аккаунт.
    func login(
        emailOrPhone: String,
        password: String
    ) async throws -> AuthResponse
    
    /// Запуск гостевой сессии (пользователь пропустил авторизацию).
    func startGuestSession() async -> User
}

// MARK: - AuthService (реальная реализация через NetworkService)
final class AuthService: AuthServiceProtocol {
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func register(
        emailOrPhone: String,
        name: String,
        password: String
    ) async throws -> AuthResponse {
        // TODO: заменить валидацию и эндпоинт на фактические с бэкенда.
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuthError.validationFailed("Имя не может быть пустым")
        }
        guard password.count >= 6 else {
            throw AuthError.validationFailed("Пароль должен быть не короче 6 символов")
        }
        
        let endpoint = Endpoint(
            path: "/auth/register",
            method: .post,
            bodyParameters: [
                "email_or_phone": emailOrPhone,
                "name": name,
                "password": password
            ]
        )
        
        do {
            let response: AuthResponse = try await networkService.request(endpoint)
            AuthManager.shared.setSession(user: response.user, token: response.token, isGuest: false)
            return response
        } catch let error as NetworkError {
            throw AuthError.network(error)
        } catch {
            throw AuthError.unknown
        }
    }
    
    func login(
        emailOrPhone: String,
        password: String
    ) async throws -> AuthResponse {
        guard !emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuthError.validationFailed("Введите почту или номер телефона")
        }
        guard password.count >= 6 else {
            throw AuthError.validationFailed("Пароль должен быть не короче 6 символов")
        }
        
        let endpoint = Endpoint(
            path: "/auth/login",
            method: .post,
            bodyParameters: [
                "email_or_phone": emailOrPhone,
                "password": password
            ]
        )
        
        do {
            let response: AuthResponse = try await networkService.request(endpoint)
            AuthManager.shared.setSession(user: response.user, token: response.token, isGuest: false)
            return response
        } catch let error as NetworkError {
            throw AuthError.network(error)
        } catch {
            throw AuthError.invalidCredentials
        }
    }
    
    func startGuestSession() async -> User {
        let guest = User(
            id: -1,
            name: "Гость",
            email: nil,
            phone: nil,
            isGuest: true
        )
        AuthManager.shared.setGuestSession()
        return guest
    }
}

// MARK: - MockAuthService
/// Мок‑реализация авторизации, не обращается к сети.
final class MockAuthService: AuthServiceProtocol {
    
    func register(
        emailOrPhone: String,
        name: String,
        password: String
    ) async throws -> AuthResponse {
        let user = User(
            id: Int.random(in: 1...999_999),
            name: name,
            email: emailOrPhone.contains("@") ? emailOrPhone : nil,
            phone: emailOrPhone.contains("@") ? nil : emailOrPhone,
            isGuest: false
        )
        let token = UUID().uuidString
        let response = AuthResponse(user: user, token: token)
        AuthManager.shared.setSession(user: user, token: token, isGuest: false)
        return response
    }
    
    func login(
        emailOrPhone: String,
        password: String
    ) async throws -> AuthResponse {
        // Для моков просто генерируем пользователя.
        let user = User(
            id: Int.random(in: 1...999_999),
            name: "Карина",
            email: emailOrPhone.contains("@") ? emailOrPhone : nil,
            phone: emailOrPhone.contains("@") ? nil : emailOrPhone,
            isGuest: false
        )
        let token = "mock-token-\(UUID().uuidString)"
        let response = AuthResponse(user: user, token: token)
        AuthManager.shared.setSession(user: user, token: token, isGuest: false)
        return response
    }
    
    func startGuestSession() async -> User {
        let guest = User(
            id: -1,
            name: "Гость",
            email: nil,
            phone: nil,
            isGuest: true
        )
        AuthManager.shared.setGuestSession()
        return guest
    }
}

