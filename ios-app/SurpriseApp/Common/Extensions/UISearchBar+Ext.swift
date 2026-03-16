import UIKit

extension UISearchBar {

    func applyCustomStyle(
        backgroundColor: UIColor = .appSecondary,
        textColor: UIColor = .appBackground,
        placeholderColor: UIColor = .appWhite,
        placeholderText: String? = nil,
        iconColor: UIColor = .appPrimary,
        cornerRadius: CGFloat = 12
    ) {
        self.backgroundImage = UIImage()
        self.barTintColor = .clear

        let textField = self.searchTextField
        textField.backgroundColor = backgroundColor
        textField.textColor = textColor
        textField.layer.cornerRadius = cornerRadius
        textField.layer.masksToBounds = true

        if let placeholderText = placeholderText ?? self.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholderText,
                attributes: [.foregroundColor: placeholderColor]
            )
        }

        if let leftIcon = textField.leftView as? UIImageView {
            leftIcon.image = leftIcon.image?.withRenderingMode(.alwaysTemplate)
            leftIcon.tintColor = iconColor
        }

        if let clearButton = textField.value(forKey: "clearButton") as? UIButton {
            clearButton.tintColor = iconColor
        }
    }
}
