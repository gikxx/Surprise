import UIKit

/// Тонкий wrapper над UIFeedbackGenerator-API для тактильной обратной связи.
///
/// На каждый вызов создаётся новый generator, который подготавливается и
/// сразу триггерит отдачу. Generators дёшево создавать; держать их
/// долгоживущими нет смысла — Apple сама гасит/возвращает железку через
/// несколько секунд, и поэтому единичный одноразовый генератор работает
/// предсказуемо.
///
/// Примеры использования:
///   HapticFeedback.tap()            — лёгкий тап (тап на карточку, скролл)
///   HapticFeedback.like()           — добавление в избранное
///   HapticFeedback.selection()      — переключение чипса категории
///   HapticFeedback.success()        — сохранение профиля, успешный логин
///   HapticFeedback.warning()        — некритичная ошибка (валидация)
///   HapticFeedback.error()          — серверная ошибка, разрыв сети
enum HapticFeedback {

    /// Лёгкий «cushion-style» удар. Подходит для тапов по карточкам,
    /// открытий деталей, переходов на новый экран.
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Чуть более выраженный удар. Лайк подарка, нажатие на «Сохранить».
    static func like() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Системный «picker tick» — лёгкий щелчок переключения. Идеально
    /// подходит для чипсов категорий, табов, переключателей.
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    /// Двойной мажорный паттерн «всё получилось».
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Паттерн «осторожно, не пройдёт» — для валидационных ошибок.
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    /// Резкий паттерн «сломалось» — серверные/сетевые ошибки.
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}
