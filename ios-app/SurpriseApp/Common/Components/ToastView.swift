import UIKit

/// Внутри-приложенческий тост-баннер. Появляется сверху, сам прячется
/// через несколько секунд. Не блокирует интерфейс — это не alert.
///
/// Дизайн зафиксирован под макет из Figma: голубой фон #BDD3E9,
/// коричневый текст (appPrimary), мягко закруглённый прямоугольник.
/// Ширина ~2/3 экрана, высота 51pt.
///
/// Использование:
///     Toast.show("Подарок успешно сохранён")
///     Toast.show("Не удалось сохранить", duration: 3)
enum Toast {

    /// Размеры из Figma. На широких устройствах ширина клипуется
    /// шириной экрана с горизонтальными отступами.
    private static let figmaWidth: CGFloat = 288
    private static let figmaHeight: CGFloat = 51
    private static let topInset: CGFloat = 12
    private static let horizontalInset: CGFloat = 16

    /// Показать тост в активной сцене.
    /// - Parameters:
    ///   - message: текст сообщения
    ///   - duration: время автоматического скрытия в секундах
    static func show(_ message: String, duration: TimeInterval = 2.5) {
        guard let window = activeWindow() else { return }

        let toast = ToastView(message: message)
        toast.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(toast)

        let metrics = resolvedMetrics(for: window.bounds.width)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            toast.widthAnchor.constraint(equalToConstant: metrics.width),
            toast.heightAnchor.constraint(equalToConstant: metrics.height),
        ])

        // Стартовая позиция — выше верхней границы экрана, скрыто.
        let topAnchor = toast.topAnchor.constraint(
            equalTo: window.safeAreaLayoutGuide.topAnchor,
            constant: -metrics.height - topInset
        )
        topAnchor.isActive = true
        window.layoutIfNeeded()

        // Анимация выезда.
        topAnchor.constant = topInset
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.78,
            initialSpringVelocity: 0.4
        ) {
            window.layoutIfNeeded()
        }

        // Автоматическое скрытие.
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            topAnchor.constant = -metrics.height - topInset
            UIView.animate(withDuration: 0.3, animations: {
                window.layoutIfNeeded()
                toast.alpha = 0
            }, completion: { _ in
                toast.removeFromSuperview()
            })
        }
    }

    // MARK: - Private

    /// Foreground-active UIWindow для текущей сцены. На iOS 13+ сцен может
    /// быть несколько (multi-window на iPad), берём активную.
    private static func activeWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first
    }

    private static func resolvedMetrics(for containerWidth: CGFloat) -> (width: CGFloat, height: CGFloat) {
        // База из Figma: 288x51.
        // На телефонах ширина близка к макету, на iPad — растёт, но остаётся
        // компактной плашкой (не во всю ширину).
        let preferredByScreen = containerWidth * (2.0 / 3.0)
        let maxByInsets = max(containerWidth - (horizontalInset * 2), 220)
        let width = min(max(preferredByScreen, figmaWidth), maxByInsets, 560)
        let height = figmaHeight
        return (width: width, height: height)
    }
}

// MARK: - ToastView

private final class ToastView: UIView {

    /// Голубой фон тоста — точное значение из макета.
    private static let backgroundHex = "#BDD3E9"

    private let messageLabel = UILabel()

    init(message: String) {
        super.init(frame: .zero)

        backgroundColor = UIColor(hex: Self.backgroundHex)

        // Мягкий квадрат — не капсула, но достаточно скруглён, чтобы не
        // выглядеть жёстко. ~22pt при высоте 51pt = «soft square».
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous

        messageLabel.text = message
        messageLabel.font = .helveticaRegular(size: 17)
        messageLabel.textColor = .appPrimary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 1
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.minimumScaleFactor = 0.8
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
