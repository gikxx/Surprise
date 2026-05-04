import XCTest
@testable import SurpriseApp

// MARK: - AuthManagerTests
// AuthManager использует UserDefaults.standard напрямую через статический синглтон.
// Тесты работают через AuthManager.shared и очищают UserDefaults в tearDown.

@MainActor
final class AuthManagerTests: XCTestCase {

    private var sut: AuthManager { AuthManager.shared }

    // Ключи, которые нужно зачистить между тестами
    private let keysToClean = [
        "auth_token", "auth_refresh_token", "auth_user_id",
        "auth_user_name", "auth_user_email", "auth_user_phone",
        "auth_is_guest", "auth_user_avatar"
    ]

    override func setUp() {
        super.setUp()
        cleanDefaults()
    }

    override func tearDown() {
        cleanDefaults()
        super.tearDown()
    }

    private func cleanDefaults() {
        keysToClean.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    private func makeUser(
        id: Int = 1,
        name: String = "Карина",
        email: String? = "k@test.com",
        phone: String? = nil,
        avatarUrl: String? = nil
    ) -> User {
        User(id: id, name: name, email: email, phone: phone, isGuest: false, avatarUrl: avatarUrl)
    }

    // MARK: - token

    func test_token_defaultIsNil() {
        XCTAssertNil(sut.token)
    }

    func test_token_setsAndGets() {
        sut.token = "abc123"
        XCTAssertEqual(sut.token, "abc123")
    }

    func test_token_setToNilClearsValue() {
        sut.token = "abc"
        sut.token = nil
        XCTAssertNil(sut.token)
    }

    // MARK: - refreshToken

    func test_refreshToken_defaultIsNil() {
        XCTAssertNil(sut.refreshToken)
    }

    func test_refreshToken_setsAndGets() {
        sut.refreshToken = "refresh-xyz"
        XCTAssertEqual(sut.refreshToken, "refresh-xyz")
    }

    // MARK: - userId

    func test_userId_defaultIsNil() {
        XCTAssertNil(sut.userId)
    }

    func test_userId_setsAndGets() {
        sut.userId = 42
        XCTAssertEqual(sut.userId, 42)
    }

    func test_userId_setToNilClearsValue() {
        sut.userId = 5
        sut.userId = nil
        XCTAssertNil(sut.userId)
    }

    // MARK: - isGuest

    func test_isGuest_defaultIsFalse() {
        XCTAssertFalse(sut.isGuest)
    }

    func test_isGuest_setsTrue() {
        sut.isGuest = true
        XCTAssertTrue(sut.isGuest)
    }

    // MARK: - isLoggedIn

    func test_isLoggedIn_withTokenAndNotGuest_returnsTrue() {
        sut.token = "valid-token"
        sut.isGuest = false
        XCTAssertTrue(sut.isLoggedIn)
    }

    func test_isLoggedIn_withoutToken_returnsFalse() {
        sut.token = nil
        XCTAssertFalse(sut.isLoggedIn)
    }

    func test_isLoggedIn_whenGuest_returnsFalse() {
        sut.token = "token"
        sut.isGuest = true
        XCTAssertFalse(sut.isLoggedIn)
    }

    // MARK: - setSession

    func test_setSession_storesToken() {
        sut.setSession(user: makeUser(), token: "session-token", isGuest: false)
        XCTAssertEqual(sut.token, "session-token")
    }

    func test_setSession_storesUserId() {
        sut.setSession(user: makeUser(id: 99), token: "t", isGuest: false)
        XCTAssertEqual(sut.userId, 99)
    }

    func test_setSession_storesUserName() {
        sut.setSession(user: makeUser(name: "Карина"), token: "t", isGuest: false)
        XCTAssertEqual(sut.userName, "Карина")
    }

    func test_setSession_storesUserEmail() {
        sut.setSession(user: makeUser(email: "k@test.com"), token: "t", isGuest: false)
        XCTAssertEqual(sut.userEmail, "k@test.com")
    }

    func test_setSession_storesRefreshToken() {
        sut.setSession(user: makeUser(), token: "t", refreshToken: "refresh-111", isGuest: false)
        XCTAssertEqual(sut.refreshToken, "refresh-111")
    }

    func test_setSession_setsIsGuestFalse() {
        sut.setSession(user: makeUser(), token: "t", isGuest: false)
        XCTAssertFalse(sut.isGuest)
    }

    func test_setSession_withGuestTrue_setsIsGuestTrue() {
        sut.setSession(user: makeUser(), token: "t", isGuest: true)
        XCTAssertTrue(sut.isGuest)
    }

    // MARK: - updateTokens

    func test_updateTokens_updatesToken() {
        sut.token = "old-token"
        sut.updateTokens(token: "new-token", refreshToken: nil)
        XCTAssertEqual(sut.token, "new-token")
    }

    func test_updateTokens_withNonEmptyRefreshToken_updatesRefreshToken() {
        sut.updateTokens(token: "t", refreshToken: "new-refresh")
        XCTAssertEqual(sut.refreshToken, "new-refresh")
    }

    func test_updateTokens_withEmptyRefreshToken_doesNotUpdateRefreshToken() {
        sut.refreshToken = "old-refresh"
        sut.updateTokens(token: "t", refreshToken: "")
        XCTAssertEqual(sut.refreshToken, "old-refresh")
    }

    func test_updateTokens_withNilRefreshToken_doesNotUpdateRefreshToken() {
        sut.refreshToken = "keep-this"
        sut.updateTokens(token: "t", refreshToken: nil)
        XCTAssertEqual(sut.refreshToken, "keep-this")
    }

    // MARK: - updateUserInfo

    func test_updateUserInfo_updatesName() {
        sut.setSession(user: makeUser(name: "Старое"), token: "t", isGuest: false)
        sut.updateUserInfo(makeUser(name: "Новое"))
        XCTAssertEqual(sut.userName, "Новое")
    }

    func test_updateUserInfo_updatesEmail() {
        sut.updateUserInfo(makeUser(email: "new@test.com"))
        XCTAssertEqual(sut.userEmail, "new@test.com")
    }

    func test_updateUserInfo_updatesPhone() {
        sut.updateUserInfo(makeUser(phone: "+79161234567"))
        XCTAssertEqual(sut.userPhone, "+79161234567")
    }

    // MARK: - setGuestSession

    func test_setGuestSession_clearsToken() {
        sut.token = "some-token"
        sut.setGuestSession()
        XCTAssertNil(sut.token)
    }

    func test_setGuestSession_clearsUserId() {
        sut.userId = 5
        sut.setGuestSession()
        XCTAssertNil(sut.userId)
    }

    func test_setGuestSession_setsIsGuestTrue() {
        sut.setGuestSession()
        XCTAssertTrue(sut.isGuest)
    }

    func test_setGuestSession_clearsRefreshToken() {
        sut.refreshToken = "refresh"
        sut.setGuestSession()
        XCTAssertNil(sut.refreshToken)
    }

    // MARK: - logout

    func test_logout_clearsToken() {
        sut.token = "active-token"
        sut.logout()
        XCTAssertNil(sut.token)
    }

    func test_logout_clearsUserId() {
        sut.userId = 7
        sut.logout()
        XCTAssertNil(sut.userId)
    }

    func test_logout_setsIsGuestFalse() {
        sut.isGuest = true
        sut.logout()
        XCTAssertFalse(sut.isGuest)
    }

    func test_logout_clearsRefreshToken() {
        sut.refreshToken = "r"
        sut.logout()
        XCTAssertNil(sut.refreshToken)
    }

    func test_logout_isLoggedInReturnsFalse() {
        sut.setSession(user: makeUser(), token: "t", isGuest: false)
        sut.logout()
        XCTAssertFalse(sut.isLoggedIn)
    }
}
