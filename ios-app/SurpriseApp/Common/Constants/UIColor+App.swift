import UIKit

// MARK: - Design System Colors
extension UIColor {
    
    // MARK: - Main Palette
    /// Основной акцентный цвет (кнопки, активные элементы, заголовки)
    static let appPrimary = UIColor(hex: "#524141")
    
    /// Фоновый цвет для экранов
    static let appBackground = UIColor(hex: "#E7E1DB")
    
    /// Цвет для неактивных элементов/кнопок
    static let appSecondary = UIColor(hex: "#A68E8E")
    
    /// Цвет активной кнопки избранного
    static let appFavActive = UIColor(hex: "#D18BFF")
    
    /// Цвет кнопок нижней плашки навигации (Белый)
    static let appWhite = UIColor(hex: "#FFFFFF")
    
    /// Цвет основного текста
    static let appTextMain = UIColor(hex: "#000000")
    
    /// Цвет текста у кнопок
    static let appTextSecondary = UIColor(hex: "#E7E1DB")
    
    /// Цвет картинок (голубой)
    static let appImageBlue = UIColor(hex: "#7EBFFF")
    
    // MARK: - Helper Init
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") { hexSanitized.remove(at: hexSanitized.startIndex) }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}
