import XCTest
@testable import SurpriseApp

// MARK: - UserModelTests

@MainActor
final class UserModelTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - User — кастомный Decodable

    func test_user_decodesId() throws {
        let json = #"{"id":7,"name":"Карина","is_guest":false}"#.data(using: .utf8)!
        let user = try decoder.decode(User.self, from: json)
        XCTAssertEqual(user.id, 7)
    }

    func test_user_decodesName() throws {
        let json = #"{"id":1,"name":"Карина","is_guest":false}"#.data(using: .utf8)!
        let user = try decoder.decode(User.self, from: json)
        XCTAssertEqual(user.name, "Карина")
    }

    func test_user_decodesEmail() throws {
        let json = #"{"id":1,"name":"Test","email":"k@test.com","is_guest":false}"#.data(using: .utf8)!
        let user = try decoder.decode(User.self, from: json)
        XCTAssertEqual(user.email, "k@test.com")
    }

    func test_user_nilEmailDecodesAsNil() throws {
        let json = #"{"id":1,"name":"Test","is_guest":false}"#.data(using: .utf8)!
        let user = try decoder.decode(User.self, from: json)
        XCTAssertNil(user.email)
    }

    func test_user_decodesPhone() throws {
        let json = #"{"id":1,"name":"Test","phone":"+79161234567","is_guest":false}"#.data(using: .utf8)!
        let user = try decoder.decode(User.self, from: json)
        XCTAssertEqual(user.phone, "+79161234567")
    }

    func test_user_decodesIsGuestTrue() throws {
        let json = #"{"id":0,"name":"Гость","is_guest":true}"#.data(using: .utf8)!
        let user = try decoder.decode(User.self, from: json)
        XCTAssertTrue(user.isGuest)
    }

    func test_user_decodesIsGuestFalse() throws {
        let json = #"{"id":1,"name":"Test","is_guest":false}"#.data(using: .utf8)!
        let user = try decoder.decode(User.self, from: json)
        XCTAssertFalse(user.isGuest)
    }

    func test_user_decodesCreatedAt() throws {
        let json = #"{"id":1,"name":"Test","is_guest":false,"created_at":"2024-03-15T10:00:00Z"}"#.data(using: .utf8)!
        let user = try decoder.decode(User.self, from: json)
        XCTAssertNotNil(user.createdAt)
    }

    func test_user_missingCreatedAt_isNil() throws {
        let json = #"{"id":1,"name":"Test","is_guest":false}"#.data(using: .utf8)!
        let user = try decoder.decode(User.self, from: json)
        XCTAssertNil(user.createdAt)
    }

    func test_user_decodesAvatarUrl() throws {
        let json = #"{"id":1,"name":"Test","is_guest":false,"avatar_url":"https://cdn.com/avatar.jpg"}"#.data(using: .utf8)!
        let user = try decoder.decode(User.self, from: json)
        XCTAssertEqual(user.avatarUrl, "https://cdn.com/avatar.jpg")
    }

    // MARK: - User — memberwise init

    func test_user_memberwiseInit_setsAllFields() {
        let user = User(id: 42, name: "Карина", email: "k@test.com", phone: "+7999", isGuest: false)
        XCTAssertEqual(user.id, 42)
        XCTAssertEqual(user.name, "Карина")
        XCTAssertEqual(user.email, "k@test.com")
        XCTAssertEqual(user.phone, "+7999")
        XCTAssertFalse(user.isGuest)
        XCTAssertNil(user.createdAt)
    }

    func test_user_memberwiseInit_guestUser() {
        let guest = User(id: 0, name: "Гость", email: nil, phone: nil, isGuest: true)
        XCTAssertTrue(guest.isGuest)
        XCTAssertNil(guest.email)
    }

    // MARK: - AuthResponse — кастомный Decodable

    private func userJSON() -> String {
        #"{"id":1,"name":"Карина","is_guest":false}"#
    }

    func test_authResponse_decodesTokenField() throws {
        let json = """
        {"user":\(userJSON()),"token":"my-token"}
        """.data(using: .utf8)!
        let resp = try decoder.decode(AuthResponse.self, from: json)
        XCTAssertEqual(resp.token, "my-token")
    }

    func test_authResponse_decodesAccessTokenFieldAsToken() throws {
        // Бэк иногда отдаёт "access_token" вместо "token"
        let json = """
        {"user":\(userJSON()),"access_token":"access-abc"}
        """.data(using: .utf8)!
        let resp = try decoder.decode(AuthResponse.self, from: json)
        XCTAssertEqual(resp.token, "access-abc")
    }

    func test_authResponse_decodesRefreshToken() throws {
        let json = """
        {"user":\(userJSON()),"token":"t","refresh_token":"r-token"}
        """.data(using: .utf8)!
        let resp = try decoder.decode(AuthResponse.self, from: json)
        XCTAssertEqual(resp.refreshToken, "r-token")
    }

    func test_authResponse_missingRefreshToken_isNil() throws {
        let json = """
        {"user":\(userJSON()),"token":"t"}
        """.data(using: .utf8)!
        let resp = try decoder.decode(AuthResponse.self, from: json)
        XCTAssertNil(resp.refreshToken)
    }

    func test_authResponse_decodesNestedUser() throws {
        let json = """
        {"user":\(userJSON()),"token":"t"}
        """.data(using: .utf8)!
        let resp = try decoder.decode(AuthResponse.self, from: json)
        XCTAssertEqual(resp.user.id, 1)
        XCTAssertEqual(resp.user.name, "Карина")
    }

    func test_authResponse_memberwiseInit() {
        let user = User(id: 5, name: "Test", email: nil, phone: nil, isGuest: false)
        let resp = AuthResponse(user: user, token: "tok", refreshToken: "ref")
        XCTAssertEqual(resp.token, "tok")
        XCTAssertEqual(resp.refreshToken, "ref")
        XCTAssertEqual(resp.user.id, 5)
    }
}
