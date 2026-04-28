import UIKit

final class ProfileViewController: UIViewController {
    var onSettingsTapped: (() -> Void)?
    var onPersonsTapped: (() -> Void)?
    var onSupportTapped: (() -> Void)?
    var onClientInfoTapped: (() -> Void)?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Мой профиль"
        label.font = .miama(size: 36)
        label.textColor = .appPrimary
        label.textAlignment = .center
        return label
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 74
        imageView.backgroundColor = .appImageBlue.withAlphaComponent(0.45)
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .helveticaRegular(size: 24)
        label.textColor = .appPrimary
        label.textAlignment = .center
        return label
    }()
    
    private let settingsButton = UIButton.createPrimary(title: "настройки профиля")
    private let personsButton = UIButton.createPrimary(title: "мои близкие")
    private let supportButton = UIButton.createPrimary(title: "написать в поддержку")
    private let infoButton = UIButton.createPrimary(title: "инфо для клиента")
    
    private var currentUser: User
    
    init(user: User) {
        self.currentUser = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
        refreshUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        refreshUI()
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        supportButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [titleLabel, avatarImageView, nameLabel, settingsButton, personsButton, supportButton, infoButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        let buttonWidth: CGFloat = 300
        let buttonHeight: CGFloat = 55
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            avatarImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 148),
            avatarImageView.heightAnchor.constraint(equalToConstant: 148),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            settingsButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 28),
            settingsButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            settingsButton.heightAnchor.constraint(equalToConstant: buttonHeight),

            personsButton.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 24),
            personsButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            personsButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            personsButton.heightAnchor.constraint(equalToConstant: buttonHeight),

            supportButton.topAnchor.constraint(equalTo: personsButton.bottomAnchor, constant: 24),
            supportButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            supportButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            supportButton.heightAnchor.constraint(equalToConstant: buttonHeight),

            infoButton.topAnchor.constraint(equalTo: supportButton.bottomAnchor, constant: 24),
            infoButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            infoButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            infoButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -140)
        ])
        
        settingsButton.addTarget(self, action: #selector(didTapSettings), for: .touchUpInside)
        personsButton.addTarget(self, action: #selector(didTapPersons), for: .touchUpInside)
        supportButton.addTarget(self, action: #selector(didTapSupport), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(didTapInfo), for: .touchUpInside)
    }
    
    func updateUser(_ user: User) {
        currentUser = user
        refreshUI()
    }
    
    private func refreshUI() {
        nameLabel.text = currentUser.name
        updateAvatarImage()
        if currentUser.isGuest {
            settingsButton.setTitle("зарегистрироваться", for: .normal)
            personsButton.isHidden = true
        } else {
            settingsButton.setTitle("настройки профиля", for: .normal)
            personsButton.isHidden = false
        }
    }
    
    private func updateAvatarImage() {
        guard let urlString = currentUser.avatarUrl else {
            avatarImageView.image = UIImage(named: "blue_star")
            return
        }
        if urlString.hasPrefix("local://") {
            avatarImageView.image = AvatarLocalStorage.loadImage() ?? UIImage(named: "blue_star")
            return
        }
        if urlString.hasPrefix("builtin://") {
            let imageName = (urlString == "builtin://pink_star") ? "pink_star" : "blue_star"
            avatarImageView.image = UIImage(named: imageName)
            return
        }
        avatarImageView.image = UIImage(named: "blue_star")
    }
    
    @objc private func didTapSettings() {
        onSettingsTapped?()
    }

    @objc private func didTapPersons() {
        onPersonsTapped?()
    }
    
    @objc private func didTapSupport() {
        onSupportTapped?()
    }
    
    @objc private func didTapInfo() {
        onClientInfoTapped?()
    }
}
