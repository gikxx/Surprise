import UserNotifications
import UIKit

// MARK: - Holiday Model

struct AppHoliday {
    let id: String
    let name: String       // «8 Марта»
    let emoji: String      // «🌷»
    let month: Int
    let day: Int
    let reminderOffsetDays: Int   // за сколько дней напомнить
    let reminderHour: Int         // в котором часу

    /// Полное имя для баннера: «8 Марта 🌷»
    var displayName: String { "\(name) \(emoji)" }
}

// MARK: - NotificationManager

/// Центральный менеджер локальных уведомлений для SURPRISE.
///
/// Отвечает за:
/// - запрос разрешения (один раз при первом запуске)
/// - планирование ежегодных напоминаний о ключевых праздниках
/// - отображение внутри-приложенческого тоста, если праздник ≤ 14 дней
///
/// Использование:
///     // AppDelegate:
///     NotificationManager.shared.requestAuthorizationIfNeeded()
///
///     // SceneDelegate / MainCoordinator (после root VC готов):
///     NotificationManager.shared.showInAppBannerIfNeeded()
final class NotificationManager: NSObject {

    static let shared = NotificationManager()

    // MARK: - Constants

    private let center = UNUserNotificationCenter.current()
    private let permissionAskedKey = "notif_permission_asked_v1"

    // MARK: - Holidays

    static let holidays: [AppHoliday] = [
        AppHoliday(
            id: "valentines",
            name: "День святого Валентина",
            emoji: "💝",
            month: 2, day: 14,
            reminderOffsetDays: 14,
            reminderHour: 10
        ),
        AppHoliday(
            id: "feb23",
            name: "День защитника Отечества",
            emoji: "🎖️",
            month: 2, day: 23,
            reminderOffsetDays: 14,
            reminderHour: 10
        ),
        AppHoliday(
            id: "mar8",
            name: "8 Марта",
            emoji: "🌷",
            month: 3, day: 8,
            reminderOffsetDays: 14,
            reminderHour: 10
        ),
        AppHoliday(
            id: "newyear",
            name: "Новый год",
            emoji: "🎄",
            month: 1, day: 1,
            reminderOffsetDays: 14,
            reminderHour: 10
        ),
    ]

    // MARK: - Init

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Public API

    /// Запрашивает разрешение и планирует уведомления.
    /// Безопасно вызывать каждый запуск — повторного попапа не будет
    /// (iOS показывает его только один раз).
    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self?.requestPermission()
            case .authorized, .provisional, .ephemeral:
                self?.scheduleHolidayNotifications()
            case .denied:
                break  // юзер явно отказал — не настаиваем
            @unknown default:
                break
            }
        }
    }

    /// Проверяет ближайшие праздники и показывает Toast, если
    /// до праздника осталось ≤ reminderOffsetDays.
    /// Вызывать после того, как root view controller уже в иерархии.
    func showInAppBannerIfNeeded() {
        guard let upcoming = nearestUpcomingHoliday() else { return }
        let daysLeft = upcoming.daysLeft

        let message: String
        switch daysLeft {
        case 0:
            message = "Сегодня \(upcoming.holiday.displayName)! Успей удивить 🎁"
        case 1:
            message = "Завтра \(upcoming.holiday.displayName) — самое время выбрать подарок! 🎁"
        default:
            message = "До \(upcoming.holiday.displayName) \(daysLeft) \(dayWord(daysLeft)) — самое время выбрать подарок! 🎁"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            Toast.show(message, duration: 4)
        }
    }

    // MARK: - Scheduling

    func scheduleHolidayNotifications() {
        // Удаляем старые и перепланируем — безопасно при каждом запуске
        center.removeAllPendingNotificationRequests()

        for holiday in Self.holidays {
            scheduleYearlyReminder(for: holiday)
        }
    }

    // MARK: - Private

    private func requestPermission() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            if granted {
                self?.scheduleHolidayNotifications()
            }
        }
    }

    private func scheduleYearlyReminder(for holiday: AppHoliday) {
        guard let components = reminderDateComponents(
            holidayMonth: holiday.month,
            holidayDay: holiday.day,
            offsetDays: holiday.reminderOffsetDays,
            hour: holiday.reminderHour
        ) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Скоро \(holiday.displayName)"
        content.body = "До праздника \(holiday.reminderOffsetDays) дней — \nсамое время выбрать подарок в SURPRISE 🎁"
        content.sound = .default
        content.badge = 1

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "\(holiday.id)_reminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            #if DEBUG
            if let error = error {
                print("❌ Notification schedule error [\(holiday.id)]: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled notification for \(holiday.name)")
            }
            #endif
        }
    }

    /// Вычисляет DateComponents для «N дней до праздника» в нужный час.
    /// Год не включается → UNCalendarNotificationTrigger повторяет ежегодно.
    private func reminderDateComponents(
        holidayMonth: Int,
        holidayDay: Int,
        offsetDays: Int,
        hour: Int
    ) -> DateComponents? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current

        // Строим дату праздника в текущем году (год нужен только для вычисления)
        var comps = DateComponents()
        comps.year = cal.component(.year, from: Date())
        comps.month = holidayMonth
        comps.day = holidayDay

        guard
            let holidayDate = cal.date(from: comps),
            let reminderDate = cal.date(byAdding: .day, value: -offsetDays, to: holidayDate)
        else { return nil }

        // Только месяц и день — для ежегодного повтора
        var result = cal.dateComponents([.month, .day], from: reminderDate)
        result.hour = hour
        result.minute = 0
        return result
    }

    // MARK: - In-App Banner Logic

    private struct UpcomingHoliday {
        let holiday: AppHoliday
        let daysLeft: Int
    }

    /// Возвращает ближайший праздник в пределах reminderOffsetDays от сегодня, если он есть.
    private func nearestUpcomingHoliday() -> UpcomingHoliday? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current

        let today = cal.startOfDay(for: Date())
        let currentYear = cal.component(.year, from: today)

        var candidates: [UpcomingHoliday] = []

        for holiday in Self.holidays {
            // Пробуем текущий и следующий год
            for yearOffset in 0...1 {
                var comps = DateComponents()
                comps.year = currentYear + yearOffset
                comps.month = holiday.month
                comps.day = holiday.day

                guard let holidayDate = cal.date(from: comps) else { continue }
                let holidayDay = cal.startOfDay(for: holidayDate)

                let diff = cal.dateComponents([.day], from: today, to: holidayDay).day ?? Int.max
                guard diff >= 0, diff <= holiday.reminderOffsetDays else { continue }

                candidates.append(UpcomingHoliday(holiday: holiday, daysLeft: diff))
                break  // нашли в ближайшем году — дальше не смотрим
            }
        }

        // Показываем ближайший
        return candidates.min(by: { $0.daysLeft < $1.daysLeft })
    }

    // MARK: - Helpers

    private func dayWord(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod100 >= 11 && mod100 <= 14 { return "дней" }
        switch mod10 {
        case 1: return "день"
        case 2, 3, 4: return "дня"
        default: return "дней"
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Показываем уведомление прямо в приложении (foreground).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Показываем баннер + звук даже когда приложение открыто
        completionHandler([.banner, .sound])
    }

    /// Тап по уведомлению — открываем ленту подарков.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // При желании можно добавить навигацию к ленте или категории
        completionHandler()
    }
}
