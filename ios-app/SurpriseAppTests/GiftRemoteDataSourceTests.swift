import XCTest
@testable import SurpriseApp

// MARK: - GiftRemoteDataSourceTests

@MainActor
final class GiftRemoteDataSourceTests: XCTestCase {

    private var network: MockNetworkService!
    private var sut: GiftRemoteDataSource!

    override func setUp() {
        super.setUp()
        network = MockNetworkService()
        sut = GiftRemoteDataSource(networkService: network)
    }

    override func tearDown() {
        sut = nil
        network = nil
        super.tearDown()
    }

    // MARK: - JSON helpers

    private func giftListJSON(id: Int = 1, name: String = "Test Gift") -> Data {
        """
        {
            "gifts": [{
                "id": \(id), "name": "\(name)", "description": null,
                "price": 1000, "image_url": "https://img.com/x.jpg",
                "store_name": null, "store_url": null,
                "created_at": "2024-01-15T10:00:00Z",
                "is_favorite": false, "categories": [], "images": []
            }],
            "total": 1, "page": 1, "per_page": 20
        }
        """.data(using: .utf8)!
    }

    private func categoriesJSON() -> Data {
        #"[{"id": 5, "name": "Хобби"}, {"id": 6, "name": "Спорт"}]"#.data(using: .utf8)!
    }

    // MARK: - fetchAll

    func test_fetchAll_returnsGiftsFromResponse() async throws {
        // Arrange
        network.stubbedData = giftListJSON(id: 42, name: "Умные часы")

        // Act
        let gifts = try await sut.fetchAll(page: 1, perPage: 20)

        // Assert
        XCTAssertEqual(gifts.count, 1)
        XCTAssertEqual(gifts.first?.id, 42)
        XCTAssertEqual(gifts.first?.name, "Умные часы")
    }

    func test_fetchAll_callsCorrectEndpointPath() async throws {
        // Arrange
        network.stubbedData = giftListJSON()

        // Act
        _ = try await sut.fetchAll(page: 2, perPage: 50)

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/gifts")
        XCTAssertEqual(network.lastEndpoint?.method, .get)
    }

    func test_fetchAll_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true

        // Act & Assert
        do {
            _ = try await sut.fetchAll(page: 1, perPage: 20)
            XCTFail("Ожидалось исключение")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - fetchRecommended

    func test_fetchRecommended_returnsGifts() async throws {
        // Arrange
        network.stubbedData = giftListJSON(id: 7)

        // Act
        let gifts = try await sut.fetchRecommended(page: 1, perPage: 50)

        // Assert
        XCTAssertEqual(gifts.first?.id, 7)
    }

    func test_fetchRecommended_callsRecommendedPath() async throws {
        // Arrange
        network.stubbedData = giftListJSON()

        // Act
        _ = try await sut.fetchRecommended(page: 1, perPage: 50)

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/gifts/recommended")
    }

    func test_fetchRecommended_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true

        // Act & Assert
        do {
            _ = try await sut.fetchRecommended(page: 1, perPage: 10)
            XCTFail("Ожидалось исключение")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - search

    func test_search_returnsMatchingGifts() async throws {
        // Arrange
        network.stubbedData = giftListJSON(id: 99, name: "Ёжик")

        // Act
        let gifts = try await sut.search(query: "Ёжик", page: 1, perPage: 20)

        // Assert
        XCTAssertEqual(gifts.count, 1)
        XCTAssertEqual(gifts.first?.name, "Ёжик")
    }

    func test_search_callsSearchPath() async throws {
        // Arrange
        network.stubbedData = giftListJSON()

        // Act
        _ = try await sut.search(query: "тест", page: 1, perPage: 20)

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/gifts/search")
    }

    func test_search_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true

        // Act & Assert
        do {
            _ = try await sut.search(query: "q", page: 1, perPage: 20)
            XCTFail("Ожидалось исключение")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - fetchByCategory

    func test_fetchByCategory_returnsGifts() async throws {
        // Arrange
        network.stubbedData = giftListJSON(id: 3)

        // Act
        let gifts = try await sut.fetchByCategory(id: 5, page: 1, perPage: 20)

        // Assert
        XCTAssertEqual(gifts.first?.id, 3)
    }

    func test_fetchByCategory_callsGiftsPath() async throws {
        // Arrange
        network.stubbedData = giftListJSON()

        // Act
        _ = try await sut.fetchByCategory(id: 5, page: 1, perPage: 20)

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/gifts")
        XCTAssertEqual(network.lastEndpoint?.method, .get)
    }

    func test_fetchByCategory_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true

        // Act & Assert
        do {
            _ = try await sut.fetchByCategory(id: 1, page: 1, perPage: 20)
            XCTFail("Ожидалось исключение")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - fetchCategories

    func test_fetchCategories_returnsCategories() async throws {
        // Arrange
        network.stubbedData = categoriesJSON()

        // Act
        let categories = try await sut.fetchCategories()

        // Assert
        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories.first?.id, 5)
        XCTAssertEqual(categories.first?.name, "Хобби")
    }

    func test_fetchCategories_callsCategoriesPath() async throws {
        // Arrange
        network.stubbedData = categoriesJSON()

        // Act
        _ = try await sut.fetchCategories()

        // Assert
        XCTAssertEqual(network.lastEndpoint?.path, "/categories")
    }

    func test_fetchCategories_whenNetworkThrows_propagatesError() async {
        // Arrange
        network.shouldThrow = true

        // Act & Assert
        do {
            _ = try await sut.fetchCategories()
            XCTFail("Ожидалось исключение")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
