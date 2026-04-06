import UIKit

final class RegistrationViewController: UIViewController {
    var onContinue: (() -> Void)?
    var onSkip: (() -> Void)?

    private let viewModel: AuthViewModelProtocol

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "РЕГИСТРАЦИЯ"
        label.font = .helveticaBold(size: 31)
        label.textColor = .appPrimary
        label.textAlignment = .center
        return label
    }()

    // Поля с заголовками (контейнеры с UILabel + UITextField внутри)
    private let phoneEmailField = UITextField.createWithLabel(title: "почта/номер телефона")
    private let nameField = UITextField.createWithLabel(title: "имя")
    private let passwordField = UITextField.createWithLabel(title: "пароль", isSecure: true)

    private let continueButton = UIButton.createPrimary(title: "продолжить")
    private let skipButton = UIButton.createPrimary(title: "пропустить")

    // MARK: - Init
    init(viewModel: AuthViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
        setupKeyboardHandling()
    }

    private func setupUI() {
        let fieldsStack = UIStackView(arrangedSubviews: [phoneEmailField, nameField, passwordField])
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 16
        fieldsStack.distribution = .fillEqually

        [titleLabel, fieldsStack, continueButton, skipButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 42),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            fieldsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            fieldsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            fieldsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            fieldsStack.heightAnchor.constraint(equalToConstant: 245),

            continueButton.topAnchor.constraint(equalTo: fieldsStack.bottomAnchor, constant: 26),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 220),
            continueButton.heightAnchor.constraint(equalToConstant: 55),

            skipButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 16),
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.widthAnchor.constraint(equalToConstant: 220),
            skipButton.heightAnchor.constraint(equalToConstant: 55),
            skipButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])

        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(didTapSkip), for: .touchUpInside)
    }
    
    private func setupKeyboardHandling() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        let fields = inputTextFields()
        for (index, field) in fields.enumerated() {
            field.delegate = self
            field.returnKeyType = (index == fields.count - 1) ? .done : .next
        }
    }
    
    private func inputTextFields() -> [UITextField] {
        [phoneEmailField, nameField, passwordField].compactMap { container in
            container.subviews.first(where: { $0 is UITextField }) as? UITextField
        }
    }

    // MARK: - Actions
    
    @objc private func didTapContinue() {
        let emailOrPhone = text(in: phoneEmailField)
        let name = text(in: nameField)
        let password = text(in: passwordField)
        
        continueButton.isEnabled = false
        
        viewModel.register(
            emailOrPhone: emailOrPhone,
            name: name,
            password: password
        ) { [weak self] result in
            guard let self = self else { return }
            
            self.continueButton.isEnabled = true
            
            switch result {
            case .success:
                self.onContinue?()
            case .failure:
                let message = self.viewModel.errorMessage ?? "Не удалось завершить регистрацию"
                self.showAlert(message: message)
            }
        }
    }
    
    @objc private func didTapSkip() {
        onSkip?()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helpers
    
    /// Извлекает текст из внутреннего `UITextField` внутри контейнера.
    private func text(in container: UIView) -> String {
        let field = container.subviews.first(where: { $0 is UITextField }) as? UITextField
        return field?.text ?? ""
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

extension RegistrationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let fields = inputTextFields()
        guard let currentIndex = fields.firstIndex(of: textField) else {
            textField.resignFirstResponder()
            return true
        }
        
        let nextIndex = currentIndex + 1
        if nextIndex < fields.count {
            fields[nextIndex].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
}
