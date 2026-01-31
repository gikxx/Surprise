import UIKit

extension UITextField {
    static func createWithLabel(title: String, isSecure: Bool = false) -> UIView {
        let container = UIView()
        
        let label = UILabel()
        label.text = title
        label.font = .helveticaOblique(size: 20)
        label.textColor = .appTextMain
        label.textAlignment = .left
        
        let field = UITextField()
        field.backgroundColor = .appSecondary.withAlphaComponent(0.33)
        field.layer.cornerRadius = 21.5
        field.isSecureTextEntry = isSecure
        field.autocapitalizationType = .none
        
        [label, field].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 43))
        field.leftView = paddingView
        field.leftViewMode = .always
        
        // Создаем правый отступ (на случай длинного текста или кнопки очистки)
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 43))
        field.rightViewMode = .always
        
        // Устанавливаем шрифт для самого текста внутри поля
        field.font = .systemFont(ofSize: 16)
        field.textColor = .appTextMain
        
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            // Поле для ввода: отступ ровно 11 px от заголовка
            field.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            // Высота поля ровно 43 px
            field.heightAnchor.constraint(equalToConstant: 43),
            
            // Низ контейнера привязан к низу поля
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
}
