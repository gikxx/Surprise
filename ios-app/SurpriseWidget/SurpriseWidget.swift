import WidgetKit
import SwiftUI
import UIKit

// MARK: - Shared models

private struct WidgetPerson: Codable {
    let name: String
    let eventDay: Int
    let eventMonth: Int
    let eventType: String
}

// MARK: - Built-in holidays

private struct BuiltInEvent {
    let name: String
    let day: Int
    let month: Int
    let emoji: String
}

private let builtInEvents: [BuiltInEvent] = [
    BuiltInEvent(name: "Новый год",              day: 1,  month: 1,  emoji: "🎆"),
    BuiltInEvent(name: "День влюблённых",        day: 14, month: 2,  emoji: "💝"),
    BuiltInEvent(name: "23 Февраля",             day: 23, month: 2,  emoji: "🎖️"),
    BuiltInEvent(name: "8 Марта",                day: 8,  month: 3,  emoji: "🌸"),
]

// MARK: - Helpers

private func daysUntil(day: Int, month: Int) -> Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var comps = DateComponents()
    comps.day   = day
    comps.month = month
    comps.year  = calendar.component(.year, from: today)
    guard let candidate = calendar.date(from: comps) else { return 365 }
    let candidateDay = calendar.startOfDay(for: candidate)
    if candidateDay < today {
        comps.year = calendar.component(.year, from: today) + 1
        guard let next = calendar.date(from: comps) else { return 365 }
        return calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: next)).day ?? 365
    }
    return calendar.dateComponents([.day], from: today, to: candidateDay).day ?? 365
}

private func eventDateString(day: Int, month: Int) -> String {
    let months = ["января","февраля","марта","апреля","мая","июня",
                  "июля","августа","сентября","октября","ноября","декабря"]
    guard month >= 1, month <= 12 else { return "" }
    return "\(day) \(months[month - 1])"
}

private func emoji(for eventType: String) -> String {
    switch eventType {
    case "anniversary": return "💝"
    case "custom":      return "🎉"
    default:            return "🎂"
    }
}

private func symbol(for eventType: String) -> String {
    switch eventType {
    case "anniversary": return "heart.fill"
    case "custom":      return "star.fill"
    default:            return "birthday.cake.fill"
    }
}

// Маппинг встроенных праздников → SF Symbol
private let builtInSymbols: [String: String] = [
    "🎆": "sparkles",
    "💝": "heart.fill",
    "🎖️": "medal.fill",
    "🌸": "leaf.fill",
]

// MARK: - Entry

struct SurpriseEntry: TimelineEntry {
    let date: Date
    let eventName: String
    let eventDateStr: String
    let eventEmoji: String
    let eventSymbol: String   // SF Symbol name
    let daysCount: Int

    var daysLabel: String {
        switch daysCount {
        case 0:  return "Сегодня!"
        case 1:  return "Завтра"
        default: return "через \(daysCount) дн."
        }
    }
}

// MARK: - Provider

struct SurpriseProvider: TimelineProvider {

    private let appGroupId = "group.hse.surprise"
    private let personsKey = "widget_persons"

    func placeholder(in context: Context) -> SurpriseEntry {
        SurpriseEntry(date: .now,
                      eventName: "День рождения мамы",
                      eventDateStr: "6 октября",
                      eventEmoji: "🎂",
                      eventSymbol: "birthday.cake.fill",
                      daysCount: 153)
    }

    func getSnapshot(in context: Context, completion: @escaping (SurpriseEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SurpriseEntry>) -> Void) {
        let entry = makeEntry()

        // Следующее обновление — в полночь
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: Date())!
        )
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    // MARK: - Private

    private func makeEntry() -> SurpriseEntry {
        // Читаем близких из App Group
        var candidates: [(name: String, day: Int, month: Int, emoji: String, symbol: String)] = []

        if let defaults = UserDefaults(suiteName: appGroupId),
           let data = defaults.data(forKey: personsKey),
           let persons = try? JSONDecoder().decode([WidgetPerson].self, from: data) {
            for p in persons {
                candidates.append((p.name, p.eventDay, p.eventMonth,
                                   emoji(for: p.eventType),
                                   symbol(for: p.eventType)))
            }
        }

        // Добавляем встроенные праздники
        for h in builtInEvents {
            candidates.append((h.name, h.day, h.month, h.emoji,
                               builtInSymbols[h.emoji] ?? "sparkles"))
        }

        // Ближайшее событие
        let nearest = candidates.min { daysUntil(day: $0.day, month: $0.month) < daysUntil(day: $1.day, month: $1.month) }

        guard let event = nearest else {
            return SurpriseEntry(date: .now,
                                 eventName: "Новый год",
                                 eventDateStr: "1 января",
                                 eventEmoji: "🎆",
                                 eventSymbol: "sparkles",
                                 daysCount: daysUntil(day: 1, month: 1))
        }

        let days = daysUntil(day: event.day, month: event.month)
        return SurpriseEntry(
            date: .now,
            eventName: event.name,
            eventDateStr: eventDateString(day: event.day, month: event.month),
            eventEmoji: event.emoji,
            eventSymbol: event.symbol,
            daysCount: days
        )
    }
}

// MARK: - Widget View


struct SurpriseWidgetEntryView: View {

    var entry: SurpriseEntry

    private let beige   = Color(red: 231/255, green: 225/255, blue: 219/255) // #E7E1DB
    private let primary = Color(red: 82/255,  green: 65/255,  blue: 65/255)  // #524141
    private let accent  = Color(red: 189/255, green: 211/255, blue: 233/255) // #BDD3E9

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Image(systemName: entry.eventSymbol)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(accent)

            Spacer()

            Text(entry.eventName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(entry.eventDateStr)
                .font(.system(size: 11))
                .foregroundColor(primary.opacity(0.55))
                .padding(.top, 2)

            Text(entry.daysLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(daysColor)
                .padding(.top, 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var daysColor: Color {
        switch entry.daysCount {
        case 0...1:  return Color(red: 232/255, green: 124/255, blue: 124/255)
        case 2...7:  return Color(red: 232/255, green: 168/255, blue: 124/255)
        default:     return primary.opacity(0.7)
        }
    }
}

// MARK: - Widget

struct SurpriseWidget: Widget {
    let kind = "SurpriseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SurpriseProvider()) { entry in
            SurpriseWidgetEntryView(entry: entry)
                .containerBackground(
                    Color(red: 231/255, green: 225/255, blue: 219/255),
                    for: .widget
                )
            .widgetURL(URL(string: "surprise://feed")!)
        }
        .configurationDisplayName("Surprise")
        .description("Напомнит о ближайшем событии")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SurpriseWidget()
} timeline: {
    SurpriseEntry(date: .now,
                  eventName: "День рождения мамы",
                  eventDateStr: "6 октября",
                  eventEmoji: "🎂",
                  eventSymbol: "birthday.cake.fill",
                  daysCount: 153)
    SurpriseEntry(date: .now,
                  eventName: "8 Марта",
                  eventDateStr: "8 марта",
                  eventEmoji: "🌸",
                  eventSymbol: "leaf.fill",
                  daysCount: 2)
}
