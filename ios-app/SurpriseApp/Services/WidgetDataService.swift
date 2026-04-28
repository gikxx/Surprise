import Foundation
import WidgetKit

// MARK: - WidgetPerson
// Облегчённая версия Person для передачи в виджет через App Group.

struct WidgetPerson: Codable {
    let name: String
    let eventDay: Int
    let eventMonth: Int
    let eventType: String  // "birthday" | "anniversary" | "custom"
}

// MARK: - WidgetDataService

final class WidgetDataService {

    static let appGroupId  = "group.hse.surprise"
    static let personsKey  = "widget_persons"

    /// Сохраняет список близких в общий контейнер и обновляет виджет.
    /// Кодирование и запись — в фоне, reloadAllTimelines — тоже не блокирует UI.
    static func save(_ persons: [Person]) {
        let widgetPersons = persons.map {
            WidgetPerson(name: $0.name,
                         eventDay: $0.eventDay,
                         eventMonth: $0.eventMonth,
                         eventType: $0.eventType.rawValue)
        }

        DispatchQueue.global(qos: .background).async {
            guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
            if let data = try? JSONEncoder().encode(widgetPersons) {
                defaults.set(data, forKey: personsKey)
                defaults.synchronize()
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
