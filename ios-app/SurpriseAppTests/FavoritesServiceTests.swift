import XCTest
@testable import SurpriseApp

// MARK: - FavoritesServiceTests
// FavoritesService тестируется в двух режимах:
// 1. Гостевой (token == nil) — переключение только в UserDefaults
// 2. Авторизованный (token != nil) — вызов сетевых запросов

@MainActor
final class FavoritesServiceTests: XCTestCase {

    private var network: MockNetworkService!
    private var sut: FavoritesService!
    private let favKey = "favorite_ids"

    override func setUp() {
        super.setUp()
        // Очищаем локальное хранилище и токен перед каждым тестом
        UserDefaults.standard.removeObject(forKey: favKey)
        AuthManager.shared.token = nil
        network = MockNetworkService()
        sut = FavoritesService(networkService: network, authManager: .shared)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: favKey)
        AuthManager.shared.token = nil
        sut = nil
        network = nil
        super.tearDown()
    }

    // MARK: - isFavorite

    func test_isFavorite_defaultIsFalse() {
        XCTAssertFalse(sut.isFavorite(id: 1))
    }

    func test_isFavorite_afterAddingId_returnsTrue() async {
        // Act — гостевой toggle добавляет локально
        try? await sut.toggleFavorite(id: 5)

        // Assert
        XCTAssertTrue(sut.isFavorite(id: 5))
    }

    func test_isFavorite_forUnknownId_returnsFalse() async {
        try? await sut.toggleFavorite(id: 1)
        XCTAssertFalse(sut.isFavorite(id: 99))
    }

    // MARK: - getFavoriteIds

    func test_getFavoriteIds_initiallyEmpty() {
        XCTAssertTrue(sut.getFavoriteIds().isEmpty)
    }

    func test_getFavoriteIds_afterToggle_containsId() async {
        try? await sut.toggleFavorite(id: 7)
        XCTAssertTrue(sut.getFavoriteIds().contains(7))
    }

    func test_getFavoriteIds_returnsEmptySetByDefault() {
        let ids = sut.getFavoriteIds()
        XCTAssertTrue(ids.isEmpty)
    }

    // MARK: - toggleFavorite — гостевой режим (без токена)

    func test_toggleFavorite_guestMode_addsIdToFavorites() async throws {
        // Arrange — нет токена (гостевой режим)
        // Act
        try await sut.toggleFavorite(id: 10)

        // Assert
        XCTAssertTrue(sut.isFavorite(id: 10))
    }

    func test_toggleFavorite_guestMode_removesIdWhenAlreadyFavorite() async throws {
        // Arrange — добавляем, потом убираем
        try await sut.toggleFavorite(id: 10)
        XCTAssertTrue(sut.isFavorite(id: 10))

        // Act
        try await sut.toggleFavorite(id: 10)

        // Assert
        XCTAssertFalse(sut.isFavorite(id: 10))
    }

    func test_toggleFavorite_guestMode_persistsToUserDefaults() async throws {
        // Act
        try await sut.toggleFavorite(id: 3)

        // Assert — создаём новый экземпляр сервиса, он должен загрузить данные из UserDefaults
        let newService = FavoritesService(networkService: network, authManager: .shared)
        XCTAssertTrue(newService.isFavorite(id: 3))
    }

    func test_toggleFavorite_guestMode_doesNotCallNetwork() async throws {
        // Act
        try await sut.toggleFavorite(id: 5)

        // Assert — сетевых запросов не было
        XCTAssertNil(network.lastEndpoint)
    }

    func test_toggleFavorite_guestMode_multipleIds_allPersisted() async throws {
        // Act
        try await sut.toggleFavorite(id: 1)
        try await sut.toggleFavorite(id: 2)
        try await sut.toggleFavorite(id: 3)

        // Assert
        XCTAssertEqual(sut.getFavoriteIds().count, 3)
        XCTAssertTrue(sut.isFavorite(id: 1))
        XCTAssertTrue(sut.isFavorite(id: 2))
        XCTAssertTrue(sut.isFavorite(id: 3))
    }

    // MARK: - toggleFavorite — авторизованный режим

    func test_toggleFavorite_authenticated_callsNetwork() async throws {
        // Arrange
        AuthManager.shared.token = "valid-token"
        let giftJSON = """
        {
            "id": 1, "name": "Test", "description": null, "price": 100,
            "image_url": "https://img.com/x.jpg",
            "store_name": null, "store_url": null,
            "created_at": "2024-01-01T00:00:00Z",
            "is_favorite": true, "categories": [], "images": []
        }
        """.data(using: .utf8)!
        network.stubbedData = giftJSON

        // Act
        try await sut.toggleFavorite(id: 1)

        // Assert
        XCTAssertNotNil(network.lastEndpoint)
        XCTAssertEqual(network.lastEndpoint?.path, "/favorites/1/toggle")
    }

    func test_toggleFavorite_authenticated_addsToFavoritesWhenResponseIsFavoriteTrue() async throws {
        // Arrange
        AuthManager.shared.token = "token"
        let giftJSON = """
        {
            "id": 5, "name": "Test", "description": null, "price": 100,
            "image_url": "https://img.com/x.jpg",
            "store_name": null, "store_url": null,
            "created_at": "2024-01-01T00:00:00Z",
            "is_favorite": true, "categories": [], "images": []
        }
        """.data(using: .utf8)!
        network.stubbedData = giftJSON

        // Act
        try await sut.toggleFavorite(id: 5)

        // Assert
        XCTAssertTrue(sut.isFavorite(id: 5))
    }

    func test_toggleFavorite_authenticated_removesFromFavoritesWhenResponseIsFavoriteFalse() async throws {
        // Arrange
        AuthManager.shared.token = "token"
        let giftJSON = """
        {
            "id": 5, "name": "Test", "description": null, "price": 100,
            "image_url": "https://img.com/x.jpg",
            "store_name": null, "store_url": null,
            "created_at": "2024-01-01T00:00:00Z",
            "is_favorite": false, "categories": [], "images": []
        }
        """.data(using: .utf8)!
        network.stubbedData = giftJSON
        // Предварительно добавляем в избранное
        try await sut.toggleFavorite(id: 5)
        AuthManager.shared.token = "token"
        network.stubbedData = giftJSON

        // Act — сервер говорит is_favorite: false
        try await sut.toggleFavorite(id: 5)

        // Assert
        XCTAssertFalse(sut.isFavorite(id: 5))
    }

    func test_toggleFavorite_authenticated_whenNetworkThrows_propagatesError() async {
        // Arrange
        AuthManager.shared.token = "token"
        network.shouldThrow = true

        // Act & Assert
        do {
            try await sut.toggleFavorite(id: 1)
            XCTFail("Ожидалась ошибка")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - syncFromServer

    func test_syncFromServer_withoutToken_returnsImmediately() async throws {
        // Arrange — нет токена
        // Act
        try await sut.syncFromServer()

        // Assert — сеть не вызывалась
        XCTAssertNil(network.lastEndpoint)
    }

    func test_syncFromServer_withEmptyToken_returnsImmediately() async throws {
        // Arrange
        AuthManager.shared.token = ""

        // Act
        try await sut.syncFromServer()

        // Assert
        XCTAssertNil(network.lastEndpoint)
    }

    func test_syncFromServer_withToken_callsNetwork() async throws {
        // Arrange
        AuthManager.shared.token = "valid-token"
        network.stubbedData = "[]".data(using: .utf8)!

        // Act
        try await sut.syncFromServer()

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/favorites")
    }

    func test_syncFromServer_withToken_updatesFavoriteIds() async throws {
        // Arrange
        AuthManager.shared.token = "valid-token"
        let json = """
        [{
            "id": 42, "name": "Test", "description": null, "price": 100,
            "image_url": "https://img.com/x.jpg",
            "store_name": null, "store_url": null,
            "created_at": "2024-01-01T00:00:00Z",
            "is_favorite": true, "categories": [], "images": []
        }]
        """.data(using: .utf8)!
        network.stubbedData = json

        // Act
        try await sut.syncFromServer()

        // Assert
        XCTAssertTrue(sut.isFavorite(id: 42))
    }

    func test_syncFromServer_whenNetworkThrows_propagatesError() async {
        // Arrange
        AuthManager.shared.token = "token"
        network.shouldThrow = true

        // Act & Assert
        do {
            try await sut.syncFromServer()
            XCTFail("Ожидалась ошибка")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - fetchFavoriteGifts

    func test_fetchFavoriteGifts_withoutToken_returnsEmptyArray() async throws {
        // Arrange — нет токена
        // Act
        let gifts = try await sut.fetchFavoriteGifts()

        // Assert
        XCTAssertTrue(gifts.isEmpty)
    }

    func test_fetchFavoriteGifts_withToken_callsNetwork() async throws {
        // Arrange
        AuthManager.shared.token = "token"
        network.stubbedData = "[]".data(using: .utf8)!

        // Act
        let gifts = try await sut.fetchFavoriteGifts()

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/favorites")
        XCTAssertTrue(gifts.isEmpty)
    }

    func test_fetchFavoriteGifts_withToken_returnsMappedGifts() async throws {
        // Arrange
        AuthManager.shared.token = "token"
        let json = """
        [{
            "id": 7, "name": "Подарок", "description": null, "price": 500,
            "image_url": "https://img.com/g.jpg",
            "store_name": null, "store_url": null,
            "created_at": "2024-01-01T00:00:00Z",
            "is_favorite": true, "categories": [], "images": []
        }]
        """.data(using: .utf8)!
        network.stubbedData = json

        // Act
        let gifts = try await sut.fetchFavoriteGifts()

        // Assert
        XCTAssertEqual(gifts.count, 1)
        XCTAssertEqual(gifts.first?.id, 7)
        XCTAssertEqual(gifts.first?.name, "Подарок")
    }
}
