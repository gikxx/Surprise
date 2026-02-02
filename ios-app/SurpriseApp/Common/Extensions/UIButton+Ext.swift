import UIKit

extension UIButton {
    static func createPrimary(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .appSecondary
        button.setTitleColor(.appTextSecondary, for: .normal)
        
        button.titleLabel?.font = .helveticaRegular(size: 21)
        
        button.layer.cornerRadius = 27.5
        return button
    }
    
    static func createSecondary(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .appSecondary
        button.setTitleColor(.appTextSecondary, for: .normal)
        
        button.titleLabel?.font = .helveticaBold(size: 11)
        
        button.layer.cornerRadius = 20
        return button
    }
    
    static func createRound(imageName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.backgroundColor = .appSecondary
        button.tintColor = .appTextSecondary
        button.layer.cornerRadius = 27.5
        return button
    }
}
