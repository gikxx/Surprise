import Foundation

// MARK: - PersonEventType

enum PersonEventType: String, Codable, CaseIterable {
    case birthday    = "birthday"
    case anniversary = "anniversary"
    case custom      = "custom"

    var displayName: String {
        switch self {
        case .birthday:    return "День рождения"
        case .anniversary: return "Годовщина"
        case .custom:      return "Другое"
        }
    }

    var emoji: String {
        switch self {
        case .birthday:    return "🎂"
        case .anniversary: return "💝"
        case .custom:      return "🎉"
        }
    }
}

// MARK: - Person

struct Person: Codable {
    let id: Int
    let userId: Int
    let name: String
    let eventDay: Int
    let eventMonth: Int
    let eventYear: Int?
    let eventType: PersonEventType
    let notes: String?
    let avatarUrl: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId     = "user_id"
        case name
        case eventDay   = "event_day"
        case eventMonth = "event_month"
        case eventYear  = "event_year"
        case eventType  = "event_type"
        case notes
        case avatarUrl  = "avatar_url"
        case createdAt  = "created_at"
    }

    // MARK: - Computed

    /// Дней до следующего события (0 = сегодня).
    var daysUntilEvent: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var components = DateComponents()
        components.month = eventMonth
        components.day   = eventDay
        components.year  = calendar.component(.year, from: today)

        guard let candidate = calendar.date(from: components) else { return 0 }
        let candidateDay = calendar.startOfDay(for: candidate)

        if candidateDay < today {
            // Праздник в этом году уже прошёл — берём следующий год
            components.year = calendar.component(.year, from: today) + 1
            guard let next = calendar.date(from: components) else { return 0 }
            return calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: next)).day ?? 0
        }
        return calendar.dateComponents([.day], from: today, to: candidateDay).day ?? 0
    }

    /// «15 марта» или «15 марта 1990»
    var eventDateString: String {
        let months = ["января","февраля","марта","апреля","мая","июня",
                      "июля","августа","сентября","октября","ноября","декабря"]
        guard eventMonth >= 1, eventMonth <= 12 else { return "" }
        let monthName = months[eventMonth - 1]
        if let year = eventYear {
            return "\(eventDay) \(monthName) \(year)"
        }
        return "\(eventDay) \(monthName)"
    }

    /// «через N дней» / «Сегодня!» / «Завтра»
    var daysLabel: String {
        let days = daysUntilEvent
        switch days {
        case 0:  return "Сегодня! 🎉"
        case 1:  return "Завтра"
        default: return "через \(days) дн."
        }
    }

    var isUpcoming: Bool { daysUntilEvent <= 14 }
}
