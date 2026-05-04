import XCTest
@testable import SurpriseApp

// MARK: - AuthViewModelTests

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var authService: MockAuthService!
    private var sut: AuthViewModel!

    override func setUp() {
        super.setUp()
        authService = MockAuthService()
        sut = AuthViewModel(authService: authService)
    }

    override func tearDown() {
        sut = nil
        authService = nil
        super.tearDown()
    }

    // MARK: - register — успех

    func test_register_success_callsCompletionWithUser() async {
        // Arrange
        let expectedUser = User(id: 42, name: "Карина", email: "k@test.com", phone: nil, isGuest: false)
        authService.stubbedUser = expectedUser

        // Act
        let result = await withCheckedContinuation { continuation in
            sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "secret123") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        if case .success(let user) = result {
            XCTAssertEqual(user.id, 42)
            XCTAssertEqual(user.name, "Карина")
        } else {
            XCTFail("Ожидался .success, получили \(result)")
        }
    }

    func test_register_success_setsIsLoadingFalse() async {
        // Arrange / Act
        _ = await withCheckedContinuation { continuation in
            sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "secret123") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        XCTAssertFalse(sut.isLoading)
    }

    func test_register_success_clearsErrorMessage() async {
        // Arrange / Act
        _ = await withCheckedContinuation { continuation in
            sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "secret123") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        XCTAssertNil(sut.errorMessage)
    }

    func test_register_passesCorrectArgumentsToService() async {
        // Arrange / Act
        _ = await withCheckedContinuation { continuation in
            sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "qwerty6") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        XCTAssertTrue(authService.registerCalled)
        XCTAssertEqual(authService.lastEmailOrPhone, "k@test.com")
        XCTAssertEqual(authService.lastName, "Карина")
        XCTAssertEqual(authService.lastPassword, "qwerty6")
    }

    // MARK: - register — ошибка

    func test_register_invalidCredentials_setsErrorMessage() async {
        // Arrange
        authService.shouldThrow = true
        authService.stubError = AuthError.invalidCredentials

        // Act
        _ = await withCheckedContinuation { continuation in
            sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "secret") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "Неверные данные для входа")
    }

    func test_register_validationFailed_setsValidationErrorMessage() async {
        // Arrange
        authService.shouldThrow = true
        authService.stubError = AuthError.validationFailed("Email уже используется")

        // Act
        _ = await withCheckedContinuation { continuation in
            sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "secret") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        XCTAssertEqual(sut.errorMessage, "Email уже используется")
    }

    func test_register_noConnection_setsNetworkErrorMessage() async {
        // Arrange
        authService.shouldThrow = true
        authService.stubError = AuthError.network(.noConnection)

        // Act
        _ = await withCheckedContinuation { continuation in
            sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "secret") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        XCTAssertEqual(sut.errorMessage, "Нет подключения к интернету")
    }

    func test_register_unknownError_setsGenericErrorMessage() async {
        // Arrange
        authService.shouldThrow = true
        authService.stubError = AuthError.unknown

        // Act
        _ = await withCheckedContinuation { continuation in
            sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "secret") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_register_failure_setsIsLoadingFalse() async {
        // Arrange
        authService.shouldThrow = true
        authService.stubError = AuthError.unknown

        // Act
        _ = await withCheckedContinuation { continuation in
            sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "secret") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - login — успех

    func test_login_success_callsCompletionWithUser() async {
        // Arrange
        let expectedUser = User(id: 7, name: "Карина", email: "k@test.com", phone: nil, isGuest: false)
        authService.stubbedUser = expectedUser

        // Act
        let result = await withCheckedContinuation { continuation in
            sut.login(emailOrPhone: "k@test.com", password: "secret123") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        if case .success(let user) = result {
            XCTAssertEqual(user.id, 7)
        } else {
            XCTFail("Ожидался .success, получили \(result)")
        }
    }

    func test_login_success_clearsErrorMessage() async {
        // Arrange / Act
        _ = await withCheckedContinuation { continuation in
            sut.login(emailOrPhone: "k@test.com", password: "secret123") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        XCTAssertNil(sut.errorMessage)
    }

    func test_login_passesCorrectArgumentsToService() async {
        // Arrange / Act
        _ = await withCheckedContinuation { continuation in
            sut.login(emailOrPhone: "+79161234567", password: "mypass") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        XCTAssertTrue(authService.loginCalled)
        XCTAssertEqual(authService.lastEmailOrPhone, "+79161234567")
        XCTAssertEqual(authService.lastPassword, "mypass")
    }

    // MARK: - login — ошибка

    func test_login_invalidCredentials_setsErrorMessage() async {
        // Arrange
        authService.shouldThrow = true
        authService.stubError = AuthError.invalidCredentials

        // Act
        _ = await withCheckedContinuation { continuation in
            sut.login(emailOrPhone: "k@test.com", password: "wrong") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        XCTAssertEqual(sut.errorMessage, "Неверные данные для входа")
    }

    func test_login_failure_returnsFailureResult() async {
        // Arrange
        authService.shouldThrow = true
        authService.stubError = AuthError.unknown

        // Act
        let result = await withCheckedContinuation { continuation in
            sut.login(emailOrPhone: "k@test.com", password: "wrong") { result in
                continuation.resume(returning: result)
            }
        }

        // Assert
        if case .failure = result {
            // ожидаемо
        } else {
            XCTFail("Ожидался .failure, получили \(result)")
        }
    }

    // MARK: - startGuest

    func test_startGuest_callsService() async {
        // Arrange / Act
        _ = await withCheckedContinuation { continuation in
            sut.startGuest { user in
                continuation.resume(returning: user)
            }
        }

        // Assert
        XCTAssertTrue(authService.startGuestCalled)
    }

    func test_startGuest_returnsGuestUser() async {
        // Arrange / Act
        let user = await withCheckedContinuation { continuation in
            sut.startGuest { user in
                continuation.resume(returning: user)
            }
        }

        // Assert
        XCTAssertTrue(user.isGuest)
    }
}
