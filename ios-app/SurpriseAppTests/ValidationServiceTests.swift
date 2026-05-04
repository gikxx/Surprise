import XCTest
@testable import SurpriseApp

// MARK: - ValidationServiceTests

final class ValidationServiceTests: XCTestCase {

    private var sut: ValidationService!

    override func setUp() {
        super.setUp()
        sut = ValidationService.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - validateName

    func test_validateName_withNil_throwsEmptyName() {
        // Arrange
        let name: String? = nil

        // Act & Assert
        XCTAssertThrowsError(try sut.validateName(name)) { error in
            XCTAssertEqual(error as? ValidationError, .emptyName)
        }
    }

    func test_validateName_withEmptyString_throwsEmptyName() {
        // Arrange
        let name = ""

        // Act & Assert
        XCTAssertThrowsError(try sut.validateName(name)) { error in
            XCTAssertEqual(error as? ValidationError, .emptyName)
        }
    }

    func test_validateName_withWhitespaceOnly_throwsEmptyName() {
        // Arrange
        let name = "   \t\n"

        // Act & Assert
        XCTAssertThrowsError(try sut.validateName(name)) { error in
            XCTAssertEqual(error as? ValidationError, .emptyName)
        }
    }

    func test_validateName_withValidName_doesNotThrow() {
        // Arrange
        let name = "Karina"

        // Act & Assert
        XCTAssertNoThrow(try sut.validateName(name))
    }

    func test_validateName_withNameContainingSpaces_doesNotThrow() {
        // Arrange
        let name = "  Karina  "

        // Act & Assert
        XCTAssertNoThrow(try sut.validateName(name))
    }

    // MARK: - validateEmail

    func test_validateEmail_withNil_doesNotThrow() {
        // Arrange
        let email: String? = nil

        // Act & Assert
        XCTAssertNoThrow(try sut.validateEmail(email))
    }

    func test_validateEmail_withEmptyString_doesNotThrow() {
        // Arrange
        let email = ""

        // Act & Assert
        XCTAssertNoThrow(try sut.validateEmail(email))
    }

    func test_validateEmail_withValidEmail_doesNotThrow() {
        // Arrange
        let email = "user@example.com"

        // Act & Assert
        XCTAssertNoThrow(try sut.validateEmail(email))
    }

    func test_validateEmail_withValidEmailSubdomain_doesNotThrow() {
        // Arrange
        let email = "user@mail.example.co.uk"

        // Act & Assert
        XCTAssertNoThrow(try sut.validateEmail(email))
    }

    func test_validateEmail_withMissingAtSign_throwsInvalidEmail() {
        // Arrange
        let email = "userexample.com"

        // Act & Assert
        XCTAssertThrowsError(try sut.validateEmail(email)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidEmail)
        }
    }

    func test_validateEmail_withMissingDomain_throwsInvalidEmail() {
        // Arrange
        let email = "user@"

        // Act & Assert
        XCTAssertThrowsError(try sut.validateEmail(email)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidEmail)
        }
    }

    func test_validateEmail_withMissingTLD_throwsInvalidEmail() {
        // Arrange
        let email = "user@example"

        // Act & Assert
        XCTAssertThrowsError(try sut.validateEmail(email)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidEmail)
        }
    }

    // MARK: - validatePhone

    func test_validatePhone_withNil_doesNotThrow() {
        // Arrange
        let phone: String? = nil

        // Act & Assert
        XCTAssertNoThrow(try sut.validatePhone(phone))
    }

    func test_validatePhone_withEmptyString_doesNotThrow() {
        // Arrange
        let phone = ""

        // Act & Assert
        XCTAssertNoThrow(try sut.validatePhone(phone))
    }

    func test_validatePhone_withExactlyTenDigits_doesNotThrow() {
        // Arrange
        let phone = "9161234567" // ровно 10 цифр

        // Act & Assert
        XCTAssertNoThrow(try sut.validatePhone(phone))
    }

    func test_validatePhone_withFormattedPhoneElevenDigits_doesNotThrow() {
        // Arrange
        let phone = "+7 (916) 123-45-67" // 11 цифр, формат с символами

        // Act & Assert
        XCTAssertNoThrow(try sut.validatePhone(phone))
    }

    func test_validatePhone_withFewerThanTenDigits_throwsInvalidPhone() {
        // Arrange
        let phone = "916123" // только 6 цифр

        // Act & Assert
        XCTAssertThrowsError(try sut.validatePhone(phone)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidPhone)
        }
    }

    func test_validatePhone_withNineDigits_throwsInvalidPhone() {
        // Arrange
        let phone = "916123456" // 9 цифр — граничный случай

        // Act & Assert
        XCTAssertThrowsError(try sut.validatePhone(phone)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidPhone)
        }
    }

    // MARK: - validateEmailOrPhone

    func test_validateEmailOrPhone_withEmptyString_throwsEmptyEmailOrPhone() {
        // Arrange
        let value = ""

        // Act & Assert
        XCTAssertThrowsError(try sut.validateEmailOrPhone(value)) { error in
            XCTAssertEqual(error as? ValidationError, .emptyEmailOrPhone)
        }
    }

    func test_validateEmailOrPhone_withWhitespaceOnly_throwsEmptyEmailOrPhone() {
        // Arrange
        let value = "   "

        // Act & Assert
        XCTAssertThrowsError(try sut.validateEmailOrPhone(value)) { error in
            XCTAssertEqual(error as? ValidationError, .emptyEmailOrPhone)
        }
    }

    func test_validateEmailOrPhone_withValidEmail_doesNotThrow() {
        // Arrange
        let value = "karina@example.com"

        // Act & Assert
        XCTAssertNoThrow(try sut.validateEmailOrPhone(value))
    }

    func test_validateEmailOrPhone_withInvalidEmail_throwsInvalidEmailOrPhone() {
        // Arrange
        let value = "not-an-email@"

        // Act & Assert
        XCTAssertThrowsError(try sut.validateEmailOrPhone(value)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidEmailOrPhone)
        }
    }

    func test_validateEmailOrPhone_withValidPhone_doesNotThrow() {
        // Arrange
        let value = "+79161234567"

        // Act & Assert
        XCTAssertNoThrow(try sut.validateEmailOrPhone(value))
    }

    func test_validateEmailOrPhone_withShortPhone_throwsInvalidEmailOrPhone() {
        // Arrange
        let value = "12345"

        // Act & Assert
        XCTAssertThrowsError(try sut.validateEmailOrPhone(value)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidEmailOrPhone)
        }
    }

    // MARK: - validatePassword

    func test_validatePassword_withPasswordShorterThanDefault_throwsShortPassword() {
        // Arrange
        let password = "abc" // меньше 6 символов

        // Act & Assert
        XCTAssertThrowsError(try sut.validatePassword(password)) { error in
            if case ValidationError.shortPassword(let minLength) = error as! ValidationError {
                XCTAssertEqual(minLength, 6)
            } else {
                XCTFail("Expected shortPassword, got \(error)")
            }
        }
    }

    func test_validatePassword_withExactlyMinLength_doesNotThrow() {
        // Arrange
        let password = "abcdef" // ровно 6 символов

        // Act & Assert
        XCTAssertNoThrow(try sut.validatePassword(password))
    }

    func test_validatePassword_withLongerThanMinLength_doesNotThrow() {
        // Arrange
        let password = "securePassword123"

        // Act & Assert
        XCTAssertNoThrow(try sut.validatePassword(password))
    }

    func test_validatePassword_withCustomMinLength_throwsWhenTooShort() {
        // Arrange
        let password = "12345678" // 8 символов
        let minLength = 10

        // Act & Assert
        XCTAssertThrowsError(try sut.validatePassword(password, minLength: minLength)) { error in
            if case ValidationError.shortPassword(let length) = error as! ValidationError {
                XCTAssertEqual(length, minLength)
            } else {
                XCTFail("Expected shortPassword(minLength: \(minLength)), got \(error)")
            }
        }
    }

    func test_validatePassword_withCustomMinLength_doesNotThrowWhenSatisfied() {
        // Arrange
        let password = "1234567890" // ровно 10 символов
        let minLength = 10

        // Act & Assert
        XCTAssertNoThrow(try sut.validatePassword(password, minLength: minLength))
    }

    func test_validatePassword_withEmptyString_throwsShortPassword() {
        // Arrange
        let password = ""

        // Act & Assert
        XCTAssertThrowsError(try sut.validatePassword(password)) { error in
            XCTAssertNotNil(error as? ValidationError)
        }
    }
}
