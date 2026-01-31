import UIKit

final class SuccessViewController: UIViewController {
    
    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        // Делаем переносы как на макете
        let textContent = "Регистрация\nпрошла\nуспешно"
        label.text = textContent
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.8
        paragraphStyle.alignment = .left
        
        let attributedString = NSMutableAttributedString(string: textContent)
        attributedString.addAttribute(.paragraphStyle,
                                      value: paragraphStyle,
                                      range: NSRange(location: 0, length: attributedString.length))
        
        label.attributedText = attributedString
        label.textColor = .appPrimary
        label.font = .helveticaRegular(size: 51)
        label.numberOfLines = 0
        return label
    }()
    
    // Голубая звезда (нижняя)
    private let blueStar: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "star")
        iv.tintColor = .appImageBlue.withAlphaComponent(0.4)
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    // Коричневая звезда (верхняя)
    private let brownStar: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "star")
        iv.tintColor = .appSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
    }
    
    private func setupUI() {
        [titleLabel, brownStar, blueStar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            // 1. ГОЛУБАЯ звезда (нижняя)
            blueStar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 140),
            blueStar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            blueStar.widthAnchor.constraint(equalToConstant: 88),
            blueStar.heightAnchor.constraint(equalToConstant: 100),
            
            // 2. КОРИЧНЕВАЯ звезда (верхняя)
            brownStar.centerXAnchor.constraint(equalTo: blueStar.centerXAnchor),
            // Приклеиваем низ коричневой к верху голубой (0 — значит касаются лучами)
            brownStar.bottomAnchor.constraint(equalTo: blueStar.topAnchor, constant: 0),
            brownStar.widthAnchor.constraint(equalToConstant: 88),
            brownStar.heightAnchor.constraint(equalToConstant: 100),
    
            // Текст "Регистрация прошла успешно" внизу
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 42),
            titleLabel.widthAnchor.constraint(equalToConstant: 304),
            titleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -73),
            
        ])
    }
}
