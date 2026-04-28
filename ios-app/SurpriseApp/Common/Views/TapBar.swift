import UIKit

final class TapBar: UIView {
    
    var onTabSelected: ((Int) -> Void)?
    /// Вызывается когда пользователь тапает по уже активному табу
    var onTabReselected: ((Int) -> Void)?

    private var currentSelectedIndex: Int = 0
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()
    
    private var buttons: [UIButton] = []
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupLayout() {
        backgroundColor = .clear
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Настройки расстояний
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        
        // Отступы стака от краев экрана
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        createButtons()
    }
    
    // TODO: поправить иконки под одну высоту (профиль щас чуть-чуть ниже)
    private func createButtons() {
        let iconNames = ["home_icon", "heart_icon", "profile_icon"]
        
        for (index, name) in iconNames.enumerated() {
            var config = UIButton.Configuration.plain()
                    
            // Настраиваем картинку
            let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
            config.image = image
            config.imagePlacement = .top
            
            config.contentInsets = NSDirectionalEdgeInsets(top: 14.5, leading: 40, bottom: 14.5, trailing: 40)
            let button = UIButton(type: .custom)
            
            // Настройка "Овала" из макета
            button.backgroundColor = .appWhite
            button.tintColor = .appBackground // Цвет иконки (неактивный)
            button.setImage(UIImage(named: name)?.withRenderingMode(.alwaysTemplate), for: .normal)
            
            // Размеры овала
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 110).isActive = true
            button.heightAnchor.constraint(equalToConstant: 59).isActive = true
            button.layer.cornerRadius = 29.5
            
            // Тень
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 2) // Смещение вниз
            button.layer.shadowRadius = 4                        // Размытие
            button.layer.shadowOpacity = 0.1                     // Прозрачность (0.1 = 10%)
            button.layer.masksToBounds = false
            
            button.tag = index
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            
            stackView.addArrangedSubview(button)
            buttons.append(button)
        }
    }
    
    @objc private func handleTap(_ sender: UIButton) {
        if sender.tag == currentSelectedIndex {
            onTabReselected?(sender.tag)
        } else {
            onTabSelected?(sender.tag)
            updateAppearance(selectedIndex: sender.tag)
        }
    }

    func updateAppearance(selectedIndex: Int) {
        currentSelectedIndex = selectedIndex
        buttons.enumerated().forEach { index, button in
            // Активная кнопка получает яркую иконку (appPrimary)
            button.tintColor = (index == selectedIndex) ? .appPrimary : .appBackground
        }
    }
}
