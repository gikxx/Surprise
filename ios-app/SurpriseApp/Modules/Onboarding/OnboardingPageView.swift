import UIKit

// TODO: Исправить междустрочный интервал на 1 экране ( сделать меньше)

// MARK: - OnboardingPageView
final class OnboardingPageView: UIView {
    
    // MARK: - UI Elements
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = false
        imageView.tintColor = .appImageBlue.withAlphaComponent(0.4)
        return imageView
    }()
    
    private let textContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .miama(size: 32)
        label.textColor = .appPrimary
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .helveticaRegular(size: 18)
        label.textColor = .appPrimary
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true
        setupHierarchy()
        setupTextConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    func configure(with model: OnboardingPageModel) {
        backgroundImageView.image = UIImage(named: model.imageName)
        descriptionLabel.text = model.description
        
        let titleStyle = NSMutableParagraphStyle()
        titleStyle.lineSpacing = 0
    
        titleLabel.attributedText = NSAttributedString(
            string: model.title,
            attributes: [
                .font: model.description.isEmpty ? UIFont.miama(size: 38) : UIFont.miama(size: 32),
                .foregroundColor: UIColor.appPrimary,
                .paragraphStyle: titleStyle
            ]
        )
            
        setupImagePosition(for: model.imageName)
    }
    
    // MARK: - Private Methods
    private func setupHierarchy() {
        addSubview(backgroundImageView)
        addSubview(textContainer)
        
        textContainer.addSubview(titleLabel)
        textContainer.addSubview(descriptionLabel)
        
        sendSubviewToBack(backgroundImageView)
    }
    
    private func setupImagePosition(for imageName: String) {
        backgroundImageView.removeFromSuperview()
        addSubview(backgroundImageView)
        sendSubviewToBack(backgroundImageView)
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        
        switch imageName {
        case "wewewe":
            NSLayoutConstraint.activate([
                backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 100),
                backgroundImageView.topAnchor.constraint(equalTo: topAnchor, constant: 100),
                backgroundImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1),
                backgroundImageView.heightAnchor.constraint(equalTo: backgroundImageView.widthAnchor)
            ])
            
        case "star4":
            NSLayoutConstraint.activate([
                backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 100),
                backgroundImageView.topAnchor.constraint(equalTo: topAnchor, constant: 100),
                backgroundImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1),
                backgroundImageView.heightAnchor.constraint(equalTo: backgroundImageView.widthAnchor)
            ])
            
        case "tree":
            NSLayoutConstraint.activate([
                backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 80),
                backgroundImageView.topAnchor.constraint(equalTo: topAnchor, constant: 140),
                backgroundImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
                backgroundImageView.heightAnchor.constraint(equalTo: backgroundImageView.widthAnchor)
            ])
            
        case "ellipse":
            NSLayoutConstraint.activate([
                backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 100),
                backgroundImageView.topAnchor.constraint(equalTo: topAnchor, constant: 100),
                backgroundImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1),
                backgroundImageView.heightAnchor.constraint(equalTo: backgroundImageView.widthAnchor)
            ])
            
        default:
            NSLayoutConstraint.activate([
                backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 100),
                backgroundImageView.topAnchor.constraint(equalTo: topAnchor, constant: 100),
                backgroundImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1),
                backgroundImageView.heightAnchor.constraint(equalTo: backgroundImageView.widthAnchor)
            ])
        }
    }
    
    private func setupTextConstraints() {
        textContainer.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textContainer.topAnchor.constraint(equalTo: topAnchor),
            textContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            textContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            textContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 400),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 35),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 35),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40)
        ])
    }
}

// MARK: - Model
struct OnboardingPageModel {
    let title: String
    let description: String
    let imageName: String
}
