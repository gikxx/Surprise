import Foundation
import YandexMobileMetrica

final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {
        guard let apiKey = Bundle.main.infoDictionary?["APPMETRICA_API_KEY"] as? String,
              !apiKey.isEmpty else {
            print("⚠️ AppMetrica: API key not found in Info.plist")
            return
        }

        guard let configuration = YMMYandexMetricaConfiguration(apiKey: apiKey) else {
            print("⚠️ AppMetrica: Failed to create configuration")
            return
        }

        configuration.crashReporting = true
        configuration.sessionsAutoTracking = true
        configuration.handleFirstActivationAsUpdate = false

        YMMYandexMetrica.activate(with: configuration)
    }

    // MARK: - Базовые события

    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        YMMYandexMetrica.reportEvent(name, parameters: parameters, onFailure: { error in
            print("❌ AppMetrica error: \(error.localizedDescription)")
        })
    }

    func logStartScreen()  { logEvent("start_screen_view") }
    func logMainScreen()   { logEvent("main_screen_view") }
    func logAppLaunch()    { logEvent("app_launch") }

    func logBuyClick(giftId: Int) {
        logEvent("buy_click", parameters: ["gift_id": giftId])
    }

    func logAddToFavorites(giftId: Int) {
        logEvent("add_to_favorites", parameters: ["gift_id": giftId])
    }

    func logRemoveFromFavorites(giftId: Int) {
        logEvent("remove_from_favorites", parameters: ["gift_id": giftId])
    }

    func logCriticalError(scenario: String, error: Error, parameters: [String: Any]? = nil) {
        var allParams: [String: Any] = [
            "scenario": scenario,
            "error": error.localizedDescription
        ]
        if let parameters = parameters {
            allParams.merge(parameters) { $1 }
        }
        logEvent("critical_error", parameters: allParams)
    }
}
