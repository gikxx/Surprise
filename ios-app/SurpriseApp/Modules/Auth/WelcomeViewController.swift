import UIKit

final class WelcomeViewController: UIViewController {
    var onRegister: (() -> Void)?
    var onLogin: (() -> Void)?
    var onSkip: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Приветствуем!"
        label.font = .miama(size: 43)
        label.textColor = .appPrimary
        label.textAlignment = .center
        return label
    }()
    
    private let starImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "star")
        iv.tintColor = .appImageBlue
        iv.alpha = 0.4
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let registerButton = UIButton.createPrimary(title: "регистрация")
    private let loginButton = UIButton.createPrimary(title: "вход")
    private let skipButton = UIButton.createPrimary(title: "пропустить")

    override func viewDidLoad() {
        super.viewDidLoad()
        AnalyticsService.shared.logStartScreen()
        view.backgroundColor = .appBackground
        setupUI()
    }

    private func setupUI() {
        [titleLabel, registerButton, loginButton, skipButton, starImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            starImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            starImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            starImageView.widthAnchor.constraint(equalToConstant: 100),
            starImageView.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            loginButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 100),
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 216),
            loginButton.heightAnchor.constraint(equalToConstant: 56),
            
            registerButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            registerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            registerButton.widthAnchor.constraint(equalToConstant: 216),
            registerButton.heightAnchor.constraint(equalToConstant: 56),
            
            skipButton.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 16),
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.widthAnchor.constraint(equalToConstant: 216),
            skipButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        registerButton.addTarget(self, action: #selector(didTapRegister), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(didTapSkip), for: .touchUpInside)
    }

    @objc private func didTapRegister() { onRegister?() }
    @objc private func didTapLogin() { onLogin?() }
    @objc private func didTapSkip() { onSkip?() }
}
