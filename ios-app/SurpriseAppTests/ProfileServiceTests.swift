import XCTest
@testable import SurpriseApp

// MARK: - ProfileServiceTests

@MainActor
final class ProfileServiceTests: XCTestCase {

    private var network: MockNetworkService!
    private var sut: ProfileService!

    override func setUp() {
        super.setUp()
        network = MockNetworkService()
        sut = ProfileService(networkService: network)
    }

    override func tearDown() {
        sut = nil
        network = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func userJSON(
        id: Int = 1,
        name: String = "Карина",
        email: String? = "k@test.com",
        phone: String? = nil,
        isGuest: Bool = false,
        avatarUrl: String? = nil
    ) -> Data {
        var fields = """
        "id": \(id), "name": "\(name)", "is_guest": \(isGuest)
        """
        if let email = email { fields += ", \"email\": \"\(email)\"" }
        if let phone = phone { fields += ", \"phone\": \"\(phone)\"" }
        if let avatar = avatarUrl { fields += ", \"avatar_url\": \"\(avatar)\"" }
        return "{\(fields)}".data(using: .utf8)!
    }

    // MARK: - fetchProfile

    func test_fetchProfile_callsCorrectEndpoint() async throws {
        // Arrange
        network.stubbedData = userJSON()

        // Act
        _ = try await sut.fetchProfile()

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/users/me")
        XCTAssertEqual(network.lastEndpoint?.method, .get)
    }

    func test_fetchProfile_returnsDecodedUser() async throws {
        // Arrange
        network.stubbedData = userJSON(id: 42, name: "Карина")

        // Act
        let user = try await sut.fetchProfile()

        // Assert
        XCTAssertEqual(user.id, 42)
        XCTAssertEqual(user.name, "Карина")
    }

    func test_fetchProfile_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true
        network.stubError = NetworkError.noConnection

        // Act & Assert
        do {
            _ = try await sut.fetchProfile()
            XCTFail("Ожидалась ошибка")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_fetchProfile_returnsUserWithEmail() async throws {
        // Arrange
        network.stubbedData = userJSON(email: "hello@example.com")

        // Act
        let user = try await sut.fetchProfile()

        // Assert
        XCTAssertEqual(user.email, "hello@example.com")
    }

    func test_fetchProfile_returnsUserWithPhone() async throws {
        // Arrange
        network.stubbedData = userJSON(phone: "+79161234567")

        // Act
        let user = try await sut.fetchProfile()

        // Assert
        XCTAssertEqual(user.phone, "+79161234567")
    }

    func test_fetchProfile_returnsUserWithAvatarUrl() async throws {
        // Arrange
        network.stubbedData = userJSON(avatarUrl: "https://img.com/avatar.jpg")

        // Act
        let user = try await sut.fetchProfile()

        // Assert
        XCTAssertEqual(user.avatarUrl, "https://img.com/avatar.jpg")
    }

    // MARK: - updateProfile — успех

    func test_updateProfile_callsPutUsersMe() async throws {
        // Arrange
        network.stubbedData = userJSON()

        // Act
        _ = try await sut.updateProfile(name: "Новое Имя", email: nil, phone: nil)

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/users/me")
        XCTAssertEqual(network.lastEndpoint?.method, .put)
    }

    func test_updateProfile_withValidName_returnsUpdatedUser() async throws {
        // Arrange
        network.stubbedData = userJSON(name: "Новое Имя")

        // Act
        let user = try await sut.updateProfile(name: "Новое Имя", email: nil, phone: nil)

        // Assert
        XCTAssertEqual(user.name, "Новое Имя")
    }

    func test_updateProfile_withValidEmail_succeeds() async throws {
        // Arrange
        network.stubbedData = userJSON(email: "new@example.com")

        // Act
        let user = try await sut.updateProfile(name: nil, email: "new@example.com", phone: nil)

        // Assert
        XCTAssertEqual(user.email, "new@example.com")
    }

    func test_updateProfile_withValidPhone_succeeds() async throws {
        // Arrange
        network.stubbedData = userJSON(phone: "+79991234567")

        // Act
        let user = try await sut.updateProfile(name: nil, email: nil, phone: "+79991234567")

        // Assert
        XCTAssertEqual(user.phone, "+79991234567")
    }

    func test_updateProfile_withNilValues_callsNetwork() async throws {
        // Arrange
        network.stubbedData = userJSON()

        // Act
        _ = try await sut.updateProfile(name: nil, email: nil, phone: nil)

        // Assert — сеть вызывалась даже без изменений
        XCTAssertEqual(network.lastEndpoint?.path, "/users/me")
    }

    func test_updateProfile_withAllValidFields_succeeds() async throws {
        // Arrange
        network.stubbedData = userJSON(name: "Карина", email: "k@test.com", phone: "+79161234567")

        // Act
        let user = try await sut.updateProfile(
            name: "Карина",
            email: "k@test.com",
            phone: "+79161234567"
        )

        // Assert
        XCTAssertEqual(user.name, "Карина")
        XCTAssertEqual(user.email, "k@test.com")
        XCTAssertEqual(user.phone, "+79161234567")
    }

    // MARK: - updateProfile — ошибки валидации

    func test_updateProfile_withInvalidEmail_throwsValidationError() async {
        // Arrange — невалидный email
        do {
            _ = try await sut.updateProfile(name: nil, email: "not-an-email", phone: nil)
            XCTFail("Ожидалась ошибка валидации")
        } catch let error as ValidationError {
            XCTAssertEqual(error, .invalidEmail)
        } catch {
            XCTFail("Ожидался ValidationError, получили \(error)")
        }
    }

    func test_updateProfile_withInvalidPhone_throwsValidationError() async {
        // Arrange — телефон слишком короткий
        do {
            _ = try await sut.updateProfile(name: nil, email: nil, phone: "123")
            XCTFail("Ожидалась ошибка валидации")
        } catch let error as ValidationError {
            XCTAssertEqual(error, .invalidPhone)
        } catch {
            XCTFail("Ожидался ValidationError, получили \(error)")
        }
    }

    func test_updateProfile_withEmptyName_throwsValidationError() async {
        // Arrange — пустое имя
        do {
            _ = try await sut.updateProfile(name: "", email: nil, phone: nil)
            XCTFail("Ожидалась ошибка валидации")
        } catch let error as ValidationError {
            XCTAssertEqual(error, .emptyName)
        } catch {
            XCTFail("Ожидался ValidationError, получили \(error)")
        }
    }

    func test_updateProfile_withWhitespaceName_throwsValidationError() async {
        // Arrange — имя из пробелов
        do {
            _ = try await sut.updateProfile(name: "   ", email: nil, phone: nil)
            XCTFail("Ожидалась ошибка валидации")
        } catch let error as ValidationError {
            XCTAssertEqual(error, .emptyName)
        } catch {
            XCTFail("Ожидался ValidationError, получили \(error)")
        }
    }

    func test_updateProfile_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true
        network.stubbedData = nil

        // Act & Assert
        do {
            _ = try await sut.updateProfile(name: "Карина", email: nil, phone: nil)
            XCTFail("Ожидалась ошибка")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - updateAvatar

    func test_updateAvatar_callsPutUsersMe() async throws {
        // Arrange
        network.stubbedData = userJSON(avatarUrl: "https://img.com/new.jpg")

        // Act
        _ = try await sut.updateAvatar(url: "https://img.com/new.jpg")

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/users/me")
        XCTAssertEqual(network.lastEndpoint?.method, .put)
    }

    func test_updateAvatar_returnsUserWithNewAvatarUrl() async throws {
        // Arrange
        network.stubbedData = userJSON(avatarUrl: "https://img.com/new.jpg")

        // Act
        let user = try await sut.updateAvatar(url: "https://img.com/new.jpg")

        // Assert
        XCTAssertEqual(user.avatarUrl, "https://img.com/new.jpg")
    }

    func test_updateAvatar_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true

        // Act & Assert
        do {
            _ = try await sut.updateAvatar(url: "https://img.com/fail.jpg")
            XCTFail("Ожидалась ошибка")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - deleteAccount

    func test_deleteAccount_callsDeleteAuthMe() async throws {
        // Arrange — requestVoid ничего не бросает

        // Act
        try await sut.deleteAccount()

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/auth/me")
        XCTAssertEqual(network.lastEndpoint?.method, .delete)
        XCTAssertTrue(network.requestVoidCalled)
    }

    func test_deleteAccount_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true

        // Act & Assert
        do {
            try await sut.deleteAccount()
            XCTFail("Ожидалась ошибка")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_deleteAccount_doesNotCallRequestWithDecoding() async throws {
        // Act
        try await sut.deleteAccount()

        // Assert — requestVoid вызывался ровно один раз
        XCTAssertEqual(network.requestVoidCalledCount, 1)
    }
}
