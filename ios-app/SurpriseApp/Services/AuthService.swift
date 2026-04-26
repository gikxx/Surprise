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

// MARK: - AuthService
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
        try ValidationService.shared.validateName(name)
        try ValidationService.shared.validatePassword(password)
        try ValidationService.shared.validateEmailOrPhone(emailOrPhone)
        
        var body: [String: Any] = [
            "name": name,
            "password": password
        ]
        if emailOrPhone.contains("@") {
            body["email"] = emailOrPhone
        } else {
            body["phone"] = emailOrPhone
        }

        let endpoint = Endpoint(
            path: "/auth/register",
            method: .post,
            bodyParameters: body
        )
        
        do {
            let response: AuthResponse = try await networkService.request(endpoint)
            AuthManager.shared.setSession(
                user: response.user,
                token: response.token,
                refreshToken: response.refreshToken,
                isGuest: false
            )
            return response
        } catch let error as NetworkError {
            AnalyticsService.shared.logCriticalError(scenario: "registration", error: error)
            throw AuthError.network(error)
        } catch {
            AnalyticsService.shared.logCriticalError(scenario: "registration", error: error)
            throw AuthError.unknown
        }
    }

    func login(
        emailOrPhone: String,
        password: String
    ) async throws -> AuthResponse {
        try ValidationService.shared.validateEmailOrPhone(emailOrPhone)
        try ValidationService.shared.validatePassword(password)
        
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
            AuthManager.shared.setSession(
                user: response.user,
                token: response.token,
                refreshToken: response.refreshToken,
                isGuest: false
            )
            return response
        } catch let error as NetworkError {
            AnalyticsService.shared.logCriticalError(scenario: "login", error: error)
            throw AuthError.network(error)
        } catch {
            AnalyticsService.shared.logCriticalError(scenario: "login", error: error)
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
    
    private func isValidEmailOrPhone(_ value: String) -> Bool {
        if value.contains("@") {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            return emailPredicate.evaluate(with: value)
        } else {
            let digits = value.filter { $0.isNumber }
            return digits.count >= 10
        }
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
        let response = AuthResponse(user: user, token: token, refreshToken: "mock-refresh-\(UUID().uuidString)")
        AuthManager.shared.setSession(
            user: user,
            token: token,
            refreshToken: response.refreshToken,
            isGuest: false
        )
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
        let response = AuthResponse(user: user, token: token, refreshToken: "mock-refresh-\(UUID().uuidString)")
        AuthManager.shared.setSession(
            user: user,
            token: token,
            refreshToken: response.refreshToken,
            isGuest: false
        )
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


