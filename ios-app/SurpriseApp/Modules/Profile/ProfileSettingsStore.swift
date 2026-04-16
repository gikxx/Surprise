import Foundation

struct ProfileSettings {
    var name: String
    var email: String
    var phone: String
}

protocol ProfileSettingsStoreProtocol {
    func load() -> ProfileSettings
    func save(_ settings: ProfileSettings)
}

final class ProfileSettingsStore: ProfileSettingsStoreProtocol {
    private let defaults: UserDefaults
    
    private enum Keys {
        static let name = "profile_settings_name"
        static let email = "profile_settings_email"
        static let phone = "profile_settings_phone"
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func load() -> ProfileSettings {
        let storedName = defaults.string(forKey: Keys.name)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = AuthManager.shared.userName?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return ProfileSettings(
            name: (storedName?.isEmpty == false ? storedName : fallbackName) ?? "",
            email: defaults.string(forKey: Keys.email) ?? "",
            phone: defaults.string(forKey: Keys.phone) ?? ""
        )
    }
    
    func save(_ settings: ProfileSettings) {
        defaults.set(settings.name, forKey: Keys.name)
        defaults.set(settings.email, forKey: Keys.email)
        defaults.set(settings.phone, forKey: Keys.phone)
    }
}
