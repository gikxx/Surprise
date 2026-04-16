import Foundation

enum ValidationError: LocalizedError {
    case emptyName
    case invalidEmail
    case invalidPhone
    case shortPassword(minLength: Int)
    case emptyEmailOrPhone
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Имя не может быть пустым"
        case .invalidEmail:
            return "Введите корректный email"
        case .invalidPhone:
            return "Введите корректный номер телефона (минимум 10 цифр)"
        case .shortPassword(let minLength):
            return "Пароль должен быть не короче \(minLength) символов"
        case .emptyEmailOrPhone:
            return "Введите почту или номер телефона"
        }
    }
}

final class ValidationService {
    
    static let shared = ValidationService()
    private init() {}
    
    // MARK: - Public Methods
    
    func validateName(_ name: String?) throws {
        guard let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyName
        }
    }
    
    func validateEmail(_ email: String?) throws {
        guard let email = email, !email.isEmpty else {
            return // пустой email допустим (опциональное поле)
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) {
            throw ValidationError.invalidEmail
        }
    }
    
    func validatePhone(_ phone: String?) throws {
        guard let phone = phone, !phone.isEmpty else {
            return // пустой телефон допустим
        }
        
        let digits = phone.filter { $0.isNumber }
        if digits.count < 10 {
            throw ValidationError.invalidPhone
        }
    }
    
    func validateEmailOrPhone(_ value: String) throws {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyEmailOrPhone
        }
        
        if value.contains("@") {
            try validateEmail(value)
        } else {
            try validatePhone(value)
        }
    }
    
    func validatePassword(_ password: String, minLength: Int = 6) throws {
        if password.count < minLength {
            throw ValidationError.shortPassword(minLength: minLength)
        }
    }
}
