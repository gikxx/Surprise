import Foundation

// MARK: - GiftImage Model
/// Картинка из галереи подарка. Каждый Gift имеет одну "обложку"
/// (`isPrimary == true`) и опционально дополнительные кадры.
/// Бэк всегда отдаёт массив с минимум одной строкой — обложкой,
/// которая дублирует значение `Gift.imageURL` для быстрых лент.
struct GiftImage: Codable, Equatable {
    let url: String
    let sortOrder: Int
    let isPrimary: Bool
}
