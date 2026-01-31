import UIKit

final class RegistrationViewController: UIViewController {
    var onContinue: (() -> Void)?
    var onSkip: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "РЕГИСТРАЦИЯ"
        label.font = .helveticaBold(size: 31)
        label.textColor = .appPrimary
        label.textAlignment = .center
        return label
    }()

    // Поля с заголовками
    private let phoneEmailField = UITextField.createWithLabel(title: "почта/номер телефона")
    private let nameField = UITextField.createWithLabel(title: "имя")
    private let passwordField = UITextField.createWithLabel(title: "пароль", isSecure: true)

    private let continueButton = UIButton.createPrimary(title: "продолжить")
    private let skipButton = UIButton.createPrimary(title: "пропустить")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
    }

    private func setupUI() {
        let fieldsStack = UIStackView(arrangedSubviews: [phoneEmailField, nameField, passwordField])
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 25

        [titleLabel, fieldsStack, continueButton, skipButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            fieldsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            fieldsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            fieldsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            continueButton.bottomAnchor.constraint(equalTo: skipButton.topAnchor, constant: -16),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 220),
            continueButton.heightAnchor.constraint(equalToConstant: 55),

            skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.widthAnchor.constraint(equalToConstant: 220),
            skipButton.heightAnchor.constraint(equalToConstant: 55)
        ])

        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(didTapSkip), for: .touchUpInside)
    }

    @objc private func didTapContinue() { onContinue?() }
    @objc private func didTapSkip() { onSkip?() }
}
