import Foundation

final class AuthManager {
    static let shared = AuthManager()
    private init() {}
    
    private let tokenKey = "auth_token"
    private let refreshTokenKey = "auth_refresh_token"
    private let userIdKey = "auth_user_id"
    private let userNameKey = "auth_user_name"
    private let userEmailKey = "auth_user_email"
    private let userPhoneKey = "auth_user_phone"
    private let isGuestKey = "auth_is_guest"
    private let userAvatarKey = "auth_user_avatar"
    
    /// Токен авторизации текущего пользователя.
    var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }
    
    /// Refresh-токен для продления сессии.
    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: refreshTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: refreshTokenKey) }
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
    
    var userName: String? {
        get { UserDefaults.standard.string(forKey: userNameKey) }
        set { UserDefaults.standard.set(newValue, forKey: userNameKey) }
    }
    
    var userEmail: String? {
        get { UserDefaults.standard.string(forKey: userEmailKey) }
        set { UserDefaults.standard.set(newValue, forKey: userEmailKey) }
    }
    
    var userPhone: String? {
        get { UserDefaults.standard.string(forKey: userPhoneKey) }
        set { UserDefaults.standard.set(newValue, forKey: userPhoneKey) }
    }
    
    var userAvatarUrl: String? {
        get { UserDefaults.standard.string(forKey: userAvatarKey) }
        set { UserDefaults.standard.set(newValue, forKey: userAvatarKey) }
    }

    /// Флаг гостевого режима (пользователь пропустил регистрацию).
    var isGuest: Bool {
        get { UserDefaults.standard.bool(forKey: isGuestKey) }
        set { UserDefaults.standard.set(newValue, forKey: isGuestKey) }
    }
    
    var isLoggedIn: Bool {
        token != nil && isGuest == false
    }
    
    func setSession(user: User, token: String, refreshToken: String? = nil, isGuest: Bool) {
        self.token = token
        self.refreshToken = refreshToken
        self.userId = user.id
        self.userName = user.name
        self.userEmail = user.email
        self.userPhone = user.phone
        self.userAvatarUrl = user.avatarUrl
        self.isGuest = isGuest
    }
    
    func updateTokens(token: String, refreshToken: String?) {
        self.token = token
        if let refreshToken, !refreshToken.isEmpty {
            self.refreshToken = refreshToken
        }
    }
    
    func updateUserInfo(_ user: User) {
        self.userName = user.name
        self.userEmail = user.email
        self.userPhone = user.phone
        self.userAvatarUrl = user.avatarUrl
    }
    
    func setGuestSession() {
        token = nil
        refreshToken = nil
        userId = nil
        userName = nil
        userEmail = nil
        userPhone = nil
        userAvatarUrl = nil
        AvatarLocalStorage.clear()
        isGuest = true
    }
    
    func logout() {
        token = nil
        refreshToken = nil
        userId = nil
        userName = nil
        userEmail = nil
        userPhone = nil
        userAvatarUrl = nil
        AvatarLocalStorage.clear()
        isGuest = false
    }
}
