import UIKit

extension UISearchBar {

    func applyCustomStyle(
        backgroundColor: UIColor = .appSecondary,
        textColor: UIColor = .appPrimary,
        placeholderColor: UIColor = .appBackground,
        placeholderText: String? = nil,
        iconColor: UIColor = .appPrimary,
        cancelButtonColor: UIColor = .appPrimary,
        cornerRadius: CGFloat = 18
    ) {
        self.backgroundImage = UIImage()
        self.barTintColor = .clear
        self.searchBarStyle = .minimal

        let textField = self.searchTextField
        textField.alpha = 1.0
        textField.textColor = textColor
        textField.autocapitalizationType = .none
        textField.borderStyle = .none
        textField.backgroundColor = backgroundColor
        textField.layer.backgroundColor = backgroundColor.cgColor
        textField.layer.cornerRadius = cornerRadius
        textField.layer.cornerCurve = .continuous
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
            if let clearImage = clearButton.imageView?.image {
                clearButton.setImage(clearImage.withRenderingMode(.alwaysTemplate), for: .normal)
            }
        }

        self.tintColor = cancelButtonColor

        if let cancelButton = self.value(forKey: "cancelButton") as? UIButton {
            cancelButton.tintColor = cancelButtonColor
            cancelButton.setTitleColor(cancelButtonColor, for: .normal)
            cancelButton.setTitleColor(cancelButtonColor.withAlphaComponent(0.5), for: .highlighted)
        }
    }
    
    func applyCapsuleCornerRadius() {
        let h = searchTextField.bounds.height
        guard h > 0 else { return }
        searchTextField.layer.cornerRadius = h / 2
        searchTextField.layer.cornerCurve = .continuous
        searchTextField.layer.masksToBounds = true
    }
}
