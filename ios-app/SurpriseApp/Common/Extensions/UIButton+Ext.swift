import UIKit

// MARK: - RoundedButton
// Кнопка с автоматическим cornerRadius = height / 2
final class RoundedButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

extension UIButton {
    static func createPrimary(title: String) -> RoundedButton {
        let button = RoundedButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .appSecondary
        button.setTitleColor(.appTextSecondary, for: .normal)
        button.titleLabel?.font = .helveticaRegular(size: 21)
        return button
    }

    static func createSecondary(title: String) -> RoundedButton {
        let button = RoundedButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .appSecondary
        button.setTitleColor(.appTextSecondary, for: .normal)
        button.titleLabel?.font = .helveticaBold(size: 11)
        return button
    }

    static func createRound(imageName: String) -> RoundedButton {
        let button = RoundedButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.backgroundColor = .appSecondary
        button.tintColor = .appTextSecondary
        return button
    }
}
