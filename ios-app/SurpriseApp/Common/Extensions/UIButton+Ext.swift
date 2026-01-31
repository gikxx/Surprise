import UIKit

extension UIButton {
    static func createPrimary(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .appSecondary
        button.setTitleColor(.appTextSecondary, for: .normal)
        
        button.titleLabel?.font = .helveticaRegular(size: 21)
        
        button.layer.cornerRadius = 28
        return button
    }
}
