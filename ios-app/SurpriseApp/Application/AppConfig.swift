import Foundation

final class AppConfig {
    static let shared = AppConfig()

    let apiBaseURL: String

    private init(bundle: Bundle = .main) {
        if let value = bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.apiBaseURL = value
        } else {
            self.apiBaseURL = "http://127.0.0.1:8000"
        }
    }
}

