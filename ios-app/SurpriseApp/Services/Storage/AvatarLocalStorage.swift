import UIKit

/// Хранение пользовательского аватара локально, в Documents/.
///
/// На бэке мы храним только строку avatar_url. Когда пользователь выбирает
/// фото из галереи, мы:
/// 1. Сохраняем JPEG в Documents/user_avatar.jpg.
/// 2. В avatar_url пишем условный маркер `local://avatar`.
/// 3. При рендеринге смотрим на префикс avatar_url:
///    - `local://`  → читаем файл из Documents
///    - `builtin://` → используем встроенный ассет (blue_star / pink_star)
///    - всё остальное (URL) — не используется в текущей версии.
///
/// Если юзер залогинится на другом устройстве, backend вернёт avatar_url =
/// "local://avatar", но локального файла там не будет — отрисуется fallback.
/// Кросс-девайсная синхронизация фото — задача на потом (нужно реальное
/// файловое хранилище и upload-эндпоинт).
enum AvatarLocalStorage {

    /// Маркер, который записывается в User.avatarUrl, когда выбрано
    /// локальное фото из галереи.
    static let urlString = "local://avatar"

    private static let fileName = "user_avatar.jpg"

    private static var fileURL: URL {
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }

    /// Сохраняет переданное изображение как JPEG в Documents/.
    /// Возвращает строку-маркер для записи в User.avatarUrl, либо nil при ошибке.
    @discardableResult
    static func save(image: UIImage) -> String? {
        let resized = downscale(image, maxDimension: 512)
        guard let data = resized.jpegData(compressionQuality: 0.85) else {
            return nil
        }
        do {
            try data.write(to: fileURL, options: .atomic)
            return urlString
        } catch {
            #if DEBUG
            print("❌ Failed to save avatar: \(error)")
            #endif
            return nil
        }
    }

    /// Возвращает локально сохранённое фото, если оно есть.
    static func loadImage() -> UIImage? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return UIImage(contentsOfFile: fileURL.path)
    }

    /// Удаляет локальный файл (вызывается при logout).
    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Private

    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return image }

        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
