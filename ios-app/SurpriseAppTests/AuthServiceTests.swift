import XCTest
@testable import SurpriseApp

// MARK: - AuthServiceTests

@MainActor
final class AuthServiceTests: XCTestCase {

    private var network: MockNetworkService!
    private var sut: AuthService!

    override func setUp() {
        super.setUp()
        network = MockNetworkService()
        sut = AuthService(networkService: network)
        AuthManager.shared.logout()
    }

    override func tearDown() {
        AuthManager.shared.logout()
        sut = nil
        network = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func authResponseJSON(id: Int = 1, name: String = "Карина") -> Data {
        """
        {
            "user": {"id": \(id), "name": "\(name)", "is_guest": false},
            "token": "test-token",
            "refresh_token": "test-refresh"
        }
        """.data(using: .utf8)!
    }

    // MARK: - register — успех (email)

    func test_register_withEmail_callsRegisterEndpoint() async throws {
        // Arrange
        network.stubbedData = authResponseJSON()

        // Act
        _ = try await sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "password123")

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/auth/register")
        XCTAssertEqual(network.lastEndpoint?.method, .post)
    }

    func test_register_withEmail_returnsAuthResponseWithCorrectId() async throws {
        // Arrange
        network.stubbedData = authResponseJSON(id: 42)

        // Act
        let response = try await sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "password123")

        // Assert
        XCTAssertEqual(response.user.id, 42)
        XCTAssertEqual(response.token, "test-token")
    }

    func test_register_withEmail_storesTokenInAuthManager() async throws {
        // Arrange
        network.stubbedData = authResponseJSON()

        // Act
        _ = try await sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "password123")

        // Assert
        XCTAssertEqual(AuthManager.shared.token, "test-token")
        XCTAssertFalse(AuthManager.shared.isGuest)
    }

    // MARK: - register — успех (phone)

    func test_register_withPhone_callsRegisterEndpoint() async throws {
        // Arrange
        network.stubbedData = authResponseJSON()

        // Act
        _ = try await sut.register(emailOrPhone: "+79161234567", name: "Карина", password: "password123")

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/auth/register")
    }

    // MARK: - register — ошибки

    func test_register_whenNetworkError_throwsAuthNetworkError() async {
        // Arrange
        network.shouldThrow = true
        network.stubError = NetworkError.unauthorized

        // Act & Assert
        do {
            _ = try await sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "password123")
            XCTFail("Ожидалась ошибка")
        } catch let error as AuthError {
            guard case .network = error else {
                XCTFail("Ожидался .network, получили \(error)")
                return
            }
        } catch {
            XCTFail("Ожидался AuthError, получили \(error)")
        }
    }

    func test_register_whenUnknownError_throwsAuthUnknownError() async {
        // Arrange — не NetworkError → ветка .unknown
        network.shouldThrow = true
        network.stubError = URLError(.badServerResponse)

        // Act & Assert
        do {
            _ = try await sut.register(emailOrPhone: "k@test.com", name: "Карина", password: "password123")
            XCTFail("Ожидалась ошибка")
        } catch let error as AuthError {
            guard case .unknown = error else {
                XCTFail("Ожидался .unknown, получили \(error)")
                return
            }
        } catch {
            XCTFail("Ожидался AuthError")
        }
    }

    // MARK: - login — успех

    func test_login_callsLoginEndpoint() async throws {
        // Arrange
        network.stubbedData = authResponseJSON()

        // Act
        _ = try await sut.login(emailOrPhone: "k@test.com", password: "password123")

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/auth/login")
        XCTAssertEqual(network.lastEndpoint?.method, .post)
    }

    func test_login_returnsAuthResponse() async throws {
        // Arrange
        network.stubbedData = authResponseJSON(id: 7, name: "Тест")

        // Act
        let response = try await sut.login(emailOrPhone: "k@test.com", password: "password123")

        // Assert
        XCTAssertEqual(response.user.id, 7)
    }

    func test_login_storesTokenInAuthManager() async throws {
        // Arrange
        network.stubbedData = authResponseJSON()

        // Act
        _ = try await sut.login(emailOrPhone: "k@test.com", password: "password123")

        // Assert
        XCTAssertEqual(AuthManager.shared.token, "test-token")
    }

    // MARK: - login — ошибки

    func test_login_whenNetworkError_throwsAuthNetworkError() async {
        // Arrange
        network.shouldThrow = true
        network.stubError = NetworkError.noConnection

        // Act & Assert
        do {
            _ = try await sut.login(emailOrPhone: "k@test.com", password: "password123")
            XCTFail("Ожидалась ошибка")
        } catch let error as AuthError {
            guard case .network = error else {
                XCTFail("Ожидался .network, получили \(error)")
                return
            }
        } catch {
            XCTFail("Ожидался AuthError")
        }
    }

    func test_login_whenUnknownError_throwsInvalidCredentials() async {
        // Arrange — не NetworkError → ветка .invalidCredentials
        network.shouldThrow = true
        network.stubError = URLError(.timedOut)

        // Act & Assert
        do {
            _ = try await sut.login(emailOrPhone: "k@test.com", password: "password123")
            XCTFail("Ожидалась ошибка")
        } catch let error as AuthError {
            guard case .invalidCredentials = error else {
                XCTFail("Ожидался .invalidCredentials, получили \(error)")
                return
            }
        } catch {
            XCTFail("Ожидался AuthError")
        }
    }

    // MARK: - startGuestSession

    func test_startGuestSession_returnsGuestUser() async {
        // Act
        let user = await sut.startGuestSession()

        // Assert
        XCTAssertTrue(user.isGuest)
        XCTAssertEqual(user.name, "Гость")
    }

    func test_startGuestSession_setsGuestFlagInAuthManager() async {
        // Act
        _ = await sut.startGuestSession()

        // Assert
        XCTAssertTrue(AuthManager.shared.isGuest)
    }

    func test_startGuestSession_clearsExistingToken() async {
        // Arrange
        AuthManager.shared.token = "old-token"

        // Act
        _ = await sut.startGuestSession()

        // Assert
        XCTAssertNil(AuthManager.shared.token)
    }

    // MARK: - AuthError

    func test_authError_networkCase_wrapsNetworkError() {
        let error = AuthError.network(.noConnection)
        if case .network(let inner) = error {
            // Проверяем через pattern matching, т.к. NetworkError не Equatable
            if case .noConnection = inner {
                // ожидаемо
            } else {
                XCTFail("Ожидался .noConnection, получили \(inner)")
            }
        } else {
            XCTFail("Ожидался .network")
        }
    }

    func test_authError_validationFailed_hasMessage() {
        let error = AuthError.validationFailed("Email занят")
        if case .validationFailed(let msg) = error {
            XCTAssertEqual(msg, "Email занят")
        } else {
            XCTFail("Ожидался .validationFailed")
        }
    }
}
