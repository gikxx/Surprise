import XCTest
@testable import SurpriseApp

// MARK: - GiftDetailViewModelTests

@MainActor
final class GiftDetailViewModelTests: XCTestCase {

    private var favoritesService: MockFavoritesService!
    private var sut: GiftDetailViewModel!

    override func setUp() {
        super.setUp()
        favoritesService = MockFavoritesService()
    }

    override func tearDown() {
        sut = nil
        favoritesService = nil
        super.tearDown()
    }

    // MARK: - isFavorite

    func test_isFavorite_whenGiftIsInFavorites_returnsTrue() {
        // Arrange
        favoritesService.favoriteIds = [42]
        sut = GiftDetailViewModel(gift: Gift.make(id: 42), favoritesService: favoritesService)

        // Act
        let result = sut.isFavorite

        // Assert
        XCTAssertTrue(result)
    }

    func test_isFavorite_whenGiftIsNotInFavorites_returnsFalse() {
        // Arrange
        favoritesService.favoriteIds = []
        sut = GiftDetailViewModel(gift: Gift.make(id: 7), favoritesService: favoritesService)

        // Act
        let result = sut.isFavorite

        // Assert
        XCTAssertFalse(result)
    }

    func test_isFavorite_reflectsServiceState() {
        // Arrange
        favoritesService.favoriteIds = [1, 2, 3]
        sut = GiftDetailViewModel(gift: Gift.make(id: 2), favoritesService: favoritesService)

        // Act & Assert
        XCTAssertTrue(sut.isFavorite)
    }

    // MARK: - toggleFavorite — добавление в избранное

    func test_toggleFavorite_addsToFavorites_whenNotFavorite() async {
        // Arrange
        favoritesService.favoriteIds = []
        sut = GiftDetailViewModel(gift: Gift.make(id: 10, isFavorite: false), favoritesService: favoritesService)

        // Act
        let stateExpectation = expectation(description: "state changed")
        sut.onStateChanged = { stateExpectation.fulfill() }
        sut.toggleFavorite()

        await fulfillment(of: [stateExpectation], timeout: 2.0)

        // Assert
        XCTAssertTrue(favoritesService.isFavorite(id: 10))
        XCTAssertTrue(sut.gift.isFavorite)
    }

    func test_toggleFavorite_removesFromFavorites_whenAlreadyFavorite() async {
        // Arrange
        favoritesService.favoriteIds = [10]
        sut = GiftDetailViewModel(gift: Gift.make(id: 10, isFavorite: true), favoritesService: favoritesService)

        // Act
        let stateExpectation = expectation(description: "state changed")
        sut.onStateChanged = { stateExpectation.fulfill() }
        sut.toggleFavorite()

        await fulfillment(of: [stateExpectation], timeout: 2.0)

        // Assert
        XCTAssertFalse(favoritesService.isFavorite(id: 10))
        XCTAssertFalse(sut.gift.isFavorite)
    }

    func test_toggleFavorite_callsFavoritesService() async {
        // Arrange
        sut = GiftDetailViewModel(gift: Gift.make(id: 5), favoritesService: favoritesService)

        // Act
        let stateExpectation = expectation(description: "state changed")
        sut.onStateChanged = { stateExpectation.fulfill() }
        sut.toggleFavorite()

        await fulfillment(of: [stateExpectation], timeout: 2.0)

        // Assert
        XCTAssertEqual(favoritesService.toggleCalledWithId, 5)
    }

    func test_toggleFavorite_callsOnStateChanged() async {
        // Arrange
        sut = GiftDetailViewModel(gift: Gift.make(id: 1), favoritesService: favoritesService)
        var stateChangedCalled = false

        // Act
        let stateExpectation = expectation(description: "onStateChanged called")
        sut.onStateChanged = {
            stateChangedCalled = true
            stateExpectation.fulfill()
        }
        sut.toggleFavorite()

        await fulfillment(of: [stateExpectation], timeout: 2.0)

        // Assert
        XCTAssertTrue(stateChangedCalled)
    }

    // MARK: - toggleFavorite — ошибка сервиса

    func test_toggleFavorite_whenServiceThrows_doesNotCrash() async {
        // Arrange
        favoritesService.shouldThrow = true
        sut = GiftDetailViewModel(gift: Gift.make(id: 1), favoritesService: favoritesService)

        // Act — просто убеждаемся, что не крашится
        // Ждём немного, чтобы Task выполнился
        sut.toggleFavorite()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Assert — нет краша, isFavorite не изменился
        XCTAssertFalse(sut.isFavorite)
    }

    func test_toggleFavorite_whenServiceThrows_doesNotCallOnStateChanged() async {
        // Arrange
        favoritesService.shouldThrow = true
        sut = GiftDetailViewModel(gift: Gift.make(id: 1), favoritesService: favoritesService)
        var stateChangedCalled = false
        sut.onStateChanged = { stateChangedCalled = true }

        // Act
        sut.toggleFavorite()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Assert
        XCTAssertFalse(stateChangedCalled)
    }

    // MARK: - gift property

    func test_gift_returnsInitialGift() {
        // Arrange
        let gift = Gift.make(id: 99, name: "Особенный подарок", price: 9999)
        sut = GiftDetailViewModel(gift: gift, favoritesService: favoritesService)

        // Act & Assert
        XCTAssertEqual(sut.gift.id, 99)
        XCTAssertEqual(sut.gift.name, "Особенный подарок")
        XCTAssertEqual(sut.gift.price, 9999)
    }
}
