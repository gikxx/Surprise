import UIKit

final class LoginViewController: UIViewController {
    var onLoginSuccess: (() -> Void)?
    var onNoAccount: (() -> Void)?
    var onBack: (() -> Void)?

    private let viewModel: AuthViewModelProtocol
    private let shouldShowBackButton: Bool


    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "ВХОД"
        label.font = .helveticaBold(size: 31)
        label.textColor = .appPrimary
        label.textAlignment = .center
        return label
    }()

    private let phoneEmailField = UITextField.createWithLabel(title: "почта/номер телефона")
    private let passwordField = UITextField.createWithLabel(title: "пароль", isSecure: true)

    private let loginButton = UIButton.createPrimary(title: "вход")
    private let noAccountButton = UIButton.createPrimary(title: "нет аккаунта")

    init(viewModel: AuthViewModelProtocol, shouldShowBackButton: Bool = false) {
        self.viewModel = viewModel
        self.shouldShowBackButton = shouldShowBackButton
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
        if shouldShowBackButton {
            setupBackButton()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupUI() {
        let fieldsStack = UIStackView(arrangedSubviews: [phoneEmailField, passwordField])
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 16
        fieldsStack.distribution = .fillEqually
        
        [titleLabel, fieldsStack, loginButton, noAccountButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            fieldsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 34),
            fieldsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            fieldsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            fieldsStack.heightAnchor.constraint(equalToConstant: 160),
            
            loginButton.topAnchor.constraint(equalTo: fieldsStack.bottomAnchor, constant: 28),
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 220),
            loginButton.heightAnchor.constraint(equalToConstant: 55),
            
            noAccountButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            noAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noAccountButton.widthAnchor.constraint(equalToConstant: 220),
            noAccountButton.heightAnchor.constraint(equalToConstant: 55),
            noAccountButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        noAccountButton.addTarget(self, action: #selector(didTapNoAccount), for: .touchUpInside)
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
        [phoneEmailField, passwordField].compactMap { container in
            container.subviews.first(where: { $0 is UITextField }) as? UITextField
        }
    }
    
    private func text(in container: UIView) -> String {
        let field = container.subviews.first(where: { $0 is UITextField }) as? UITextField
        return field?.text ?? ""
    }
    
    @objc private func didTapLogin() {
        loginButton.isEnabled = false
        
        viewModel.login(
            emailOrPhone: text(in: phoneEmailField),
            password: text(in: passwordField)
        ) { [weak self] result in
            guard let self = self else { return }
            
            self.loginButton.isEnabled = true
            
            switch result {
            case .success:
                self.onLoginSuccess?()
            case .failure:
                let message = self.viewModel.errorMessage ?? "Не удалось выполнить вход"
                self.showAlert(message: message)
            }
        }
    }
    
    @objc private func didTapNoAccount() {
        onNoAccount?()
    }

    @objc private func didTapBack() {
        onBack?()
    }

    private func setupBackButton() {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "back_icon"), for: .normal)
        button.tintColor = .appSecondary
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            button.widthAnchor.constraint(equalToConstant: 40),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
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
