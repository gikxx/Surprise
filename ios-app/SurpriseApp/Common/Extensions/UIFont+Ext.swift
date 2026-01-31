import UIKit

extension UIFont {
    
    // MARK: - Miama Nueva
    static func miama(size: CGFloat) -> UIFont {
        return UIFont(name: "miamanueva", size: size) ?? .italicSystemFont(ofSize: size)
    }
    
    // MARK: - Helvetica
    static func helveticaRegular(size: CGFloat) -> UIFont {
        return UIFont(name: "Helvetica-Regular", size: size) ?? .systemFont(ofSize: size)
    }
    
    static func helveticaBold(size: CGFloat) -> UIFont {
        return UIFont(name: "Helvetica-Bold", size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }
    
    static func helveticaOblique(size: CGFloat) -> UIFont {
        return UIFont(name: "Helvetica-Oblique", size: size) ?? .italicSystemFont(ofSize: size)
    }
}
