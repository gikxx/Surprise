import Foundation

final class AuthManager {
    static let shared = AuthManager()
    private init() {}
    
    private let tokenKey = "auth_token"
    private let userIdKey = "auth_user_id"
    private let isGuestKey = "auth_is_guest"
    
    /// Токен авторизации текущего пользователя.
    var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    /// Идентификатор пользователя, если он известен.
    var userId: Int? {
        get {
            let value = UserDefaults.standard.integer(forKey: userIdKey)
            return value == 0 ? nil : value
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: userIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: userIdKey)
            }
        }
    }

    /// Флаг гостевого режима (пользователь пропустил регистрацию).
    var isGuest: Bool {
        get { UserDefaults.standard.bool(forKey: isGuestKey) }
        set { UserDefaults.standard.set(newValue, forKey: isGuestKey) }
    }
    
    var isLoggedIn: Bool {
        token != nil && isGuest == false
    }
    
    func setSession(user: User, token: String, isGuest: Bool) {
        self.token = token
        self.userId = user.id
        self.isGuest = isGuest
    }
    
    func setGuestSession() {
        token = nil
        userId = nil
        isGuest = true
    }
    
    func logout() {
        token = nil
        userId = nil
        isGuest = false
    }
}
