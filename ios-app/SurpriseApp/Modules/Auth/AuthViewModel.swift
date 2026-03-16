import Foundation

// MARK: - AuthViewModelProtocol
protocol AuthViewModelProtocol: AnyObject {
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func register(
        emailOrPhone: String,
        name: String,
        password: String,
        completion: @escaping (Result<User, AuthError>) -> Void
    )
    
    func startGuest(
        completion: @escaping (User) -> Void
    )
}

// MARK: - AuthViewModel
final class AuthViewModel: AuthViewModelProtocol {
    
    // MARK: - Public properties
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    
    // MARK: - Init
    init(authService: AuthServiceProtocol = MockAuthService()) {
        self.authService = authService
    }
    
    // MARK: - AuthViewModelProtocol
    
    func register(
        emailOrPhone: String,
        name: String,
        password: String,
        completion: @escaping (Result<User, AuthError>) -> Void
    ) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await authService.register(
                    emailOrPhone: emailOrPhone,
                    name: name,
                    password: password
                )
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = nil
                    completion(.success(response.user))
                }
            } catch let error as AuthError {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = Self.message(for: error)
                    completion(.failure(error))
                }
            } catch let error as NetworkError {
                let authError: AuthError = .network(error)
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = Self.message(for: authError)
                    completion(.failure(authError))
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    let authError: AuthError = .unknown
                    self.errorMessage = Self.message(for: authError)
                    completion(.failure(authError))
                }
            }
        }
    }
    
    func startGuest(
        completion: @escaping (User) -> Void
    ) {
        Task {
            let guest = await authService.startGuestSession()
            await MainActor.run {
                completion(guest)
            }
        }
    }
    
    // MARK: - Helpers
    
    private static func message(for error: AuthError) -> String {
        switch error {
        case .invalidCredentials:
            return "Неверные данные для входа"
        case .validationFailed(let message):
            return message
        case .network(let networkError):
            switch networkError {
            case .noConnection:
                return "Нет подключения к интернету"
            case .unauthorized:
                return "Сессия истекла, войдите заново"
            default:
                return "Ошибка сети, попробуйте позже"
            }
        case .unknown:
            return "Что-то пошло не так, попробуйте ещё раз"
        }
    }
}

