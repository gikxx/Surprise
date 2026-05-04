import XCTest
@testable import SurpriseApp

// MARK: - GiftRepositoryTests

@MainActor
final class GiftRepositoryTests: XCTestCase {

    private var local: MockGiftLocalDataSource!
    private var remote: MockGiftRemoteDataSource!

    override func setUp() {
        super.setUp()
        local  = MockGiftLocalDataSource()
        remote = MockGiftRemoteDataSource()
    }

    override func tearDown() {
        local  = nil
        remote = nil
        super.tearDown()
    }

    // MARK: - getAllGifts — без remote

    func test_getAllGifts_withoutRemote_usesLocalDataSource() async throws {
        // Arrange
        local.stubbedGifts = [Gift.make(id: 1), Gift.make(id: 2)]
        let sut = GiftRepository(local: local)

        // Act
        let gifts = try await sut.getAllGifts()

        // Assert
        XCTAssertEqual(gifts.count, 2)
        XCTAssertTrue(local.fetchGiftsCalled)
    }

    // MARK: - getAllGifts — с remote

    func test_getAllGifts_withRemote_usesRemoteDataSource() async throws {
        // Arrange
        remote.stubbedGifts = [Gift.make(id: 10)]
        let sut = GiftRepository(local: local, remote: remote)

        // Act
        let gifts = try await sut.getAllGifts()

        // Assert
        XCTAssertTrue(remote.fetchAllCalled)
        XCTAssertEqual(gifts.count, 1)
    }

    func test_getAllGifts_whenRemoteFails_fallsBackToLocal() async throws {
        // Arrange
        remote.shouldThrow = true
        local.stubbedGifts = [Gift.make(id: 99)]
        let sut = GiftRepository(local: local, remote: remote)

        // Act
        let gifts = try await sut.getAllGifts()

        // Assert — упал remote, подхватил local
        XCTAssertTrue(local.fetchGiftsCalled)
        XCTAssertEqual(gifts.first?.id, 99)
    }

    // MARK: - getRecommendedGifts — без remote

    func test_getRecommendedGifts_withoutRemote_sortsLocalByCreatedAt() async throws {
        // Arrange — более новый Gift.make у id:2
        let older = Gift.make(id: 1)
        let newer = Gift(
            id: 2, name: "Newer", description: nil, price: 100,
            imageURL: "", storeName: nil, storeURL: nil,
            createdAt: Date().addingTimeInterval(100),
            categories: [], images: [], isFavorite: false
        )
        local.stubbedGifts = [older, newer]
        let sut = GiftRepository(local: local)

        // Act
        let gifts = try await sut.getRecommendedGifts()

        // Assert — новее идёт первым
        XCTAssertEqual(gifts.first?.id, 2)
    }

    func test_getRecommendedGifts_withRemote_usesRemote() async throws {
        // Arrange
        remote.stubbedGifts = [Gift.make(id: 5)]
        let sut = GiftRepository(local: local, remote: remote)

        // Act
        let gifts = try await sut.getRecommendedGifts()

        // Assert
        XCTAssertTrue(remote.fetchRecommendedCalled)
        XCTAssertEqual(gifts.count, 1)
    }

    func test_getRecommendedGifts_whenRemoteFails_fallsBackToLocalSorted() async throws {
        // Arrange
        remote.shouldThrow = true
        local.stubbedGifts = [Gift.make(id: 3)]
        let sut = GiftRepository(local: local, remote: remote)

        // Act
        let gifts = try await sut.getRecommendedGifts()

        // Assert
        XCTAssertFalse(gifts.isEmpty)
    }

    // MARK: - getByCategory — без remote

    func test_getByCategory_withoutRemote_filtersLocalGiftsByCategoryId() async throws {
        // Arrange
        let cat = SurpriseApp.Category(id: 7, name: "Хобби")
        local.stubbedGifts = [
            Gift.make(id: 1, categories: [cat]),
            Gift.make(id: 2, categories: [])
        ]
        let sut = GiftRepository(local: local)

        // Act
        let gifts = try await sut.getByCategory(id: 7)

        // Assert
        XCTAssertEqual(gifts.count, 1)
        XCTAssertEqual(gifts.first?.id, 1)
    }

    func test_getByCategory_withRemote_usesRemote() async throws {
        // Arrange
        remote.stubbedGifts = [Gift.make(id: 3)]
        let sut = GiftRepository(local: local, remote: remote)

        // Act
        let gifts = try await sut.getByCategory(id: 1)

        // Assert
        XCTAssertEqual(remote.fetchByCategoryCalledWithId, 1)
        XCTAssertEqual(gifts.count, 1)
    }

    func test_getByCategory_whenRemoteFails_filtersLocalGifts() async throws {
        // Arrange
        remote.shouldThrow = true
        let cat = SurpriseApp.Category(id: 3, name: "Спорт")
        local.stubbedGifts = [
            Gift.make(id: 1, categories: [cat]),
            Gift.make(id: 2, categories: [])
        ]
        let sut = GiftRepository(local: local, remote: remote)

        // Act
        let gifts = try await sut.getByCategory(id: 3)

        // Assert
        XCTAssertEqual(gifts.count, 1)
        XCTAssertEqual(gifts.first?.id, 1)
    }

    // MARK: - search — без remote

    func test_search_withoutRemote_usesLocalSearch() async throws {
        // Arrange
        local.stubbedSearchResults = [Gift.make(id: 77, name: "Найденный")]
        let sut = GiftRepository(local: local)

        // Act
        let gifts = try await sut.search(query: "Найден")

        // Assert
        XCTAssertEqual(local.searchCalledWithQuery, "Найден")
        XCTAssertEqual(gifts.first?.id, 77)
    }

    func test_search_withRemote_usesRemoteSearch() async throws {
        // Arrange
        remote.stubbedGifts = [Gift.make(id: 88)]
        let sut = GiftRepository(local: local, remote: remote)

        // Act
        let gifts = try await sut.search(query: "ёжик")

        // Assert
        XCTAssertEqual(remote.searchCalledWithQuery, "ёжик")
        XCTAssertEqual(gifts.count, 1)
    }

    func test_search_whenRemoteFails_fallsBackToLocalSearch() async throws {
        // Arrange
        remote.shouldThrow = true
        local.stubbedSearchResults = [Gift.make(id: 55)]
        let sut = GiftRepository(local: local, remote: remote)

        // Act
        let gifts = try await sut.search(query: "test")

        // Assert
        XCTAssertEqual(local.searchCalledWithQuery, "test")
        XCTAssertEqual(gifts.first?.id, 55)
    }

    // MARK: - getCategories — без remote

    func test_getCategories_withoutRemote_usesLocalCategories() async throws {
        // Arrange
        local.stubbedCategories = [
            SurpriseApp.Category(id: 1, name: "Для неё"),
            SurpriseApp.Category(id: 2, name: "Для него")
        ]
        let sut = GiftRepository(local: local)

        // Act
        let cats = try await sut.getCategories()

        // Assert
        XCTAssertTrue(local.fetchCategoriesCalled)
        XCTAssertEqual(cats.count, 2)
    }

    func test_getCategories_withRemote_usesRemoteCategories() async throws {
        // Arrange
        remote.stubbedCategories = [SurpriseApp.Category(id: 5, name: "Хобби")]
        let sut = GiftRepository(local: local, remote: remote)

        // Act
        let cats = try await sut.getCategories()

        // Assert
        XCTAssertTrue(remote.fetchCategoriesCalled)
        XCTAssertEqual(cats.first?.id, 5)
    }

    func test_getCategories_whenRemoteFails_fallsBackToLocal() async throws {
        // Arrange
        remote.shouldThrow = true
        local.stubbedCategories = [SurpriseApp.Category(id: 9, name: "Резервная")]
        let sut = GiftRepository(local: local, remote: remote)

        // Act
        let cats = try await sut.getCategories()

        // Assert
        XCTAssertTrue(local.fetchCategoriesCalled)
        XCTAssertEqual(cats.first?.id, 9)
    }
}
