import XCTest
@testable import SurpriseApp

// MARK: - FavoritesViewModelTests

@MainActor
final class FavoritesViewModelTests: XCTestCase {

    private var repository: MockGiftRepository!
    private var favoritesService: MockFavoritesService!
    private var sut: FavoritesViewModel!

    override func setUp() {
        super.setUp()
        repository = MockGiftRepository()
        favoritesService = MockFavoritesService()
        sut = FavoritesViewModel(repository: repository, favoritesService: favoritesService)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        favoritesService = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Выставляет onStateChanged ДО вызова action, затем ждёт первого коллбэка.
    private func awaitLoad(timeout: TimeInterval = 3.0, action: () -> Void) async {
        let exp = expectation(description: "load finished")
        exp.assertForOverFulfill = false
        sut.onStateChanged = { exp.fulfill() }
        action()
        await fulfillment(of: [exp], timeout: timeout)
    }

    // MARK: - loadFavorites — сервис возвращает данные

    func test_loadFavorites_whenServiceReturnsGifts_populatesItems() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 1), Gift.make(id: 2)]
        favoritesService.favoriteIds = [1, 2]

        // Act
        await awaitLoad { self.sut.loadFavorites() }

        // Assert
        XCTAssertEqual(sut.items.count, 2)
    }

    func test_loadFavorites_whenServiceReturnsGifts_setsIsEmptyFalse() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 1)]
        favoritesService.favoriteIds = [1]

        // Act
        await awaitLoad { self.sut.loadFavorites() }

        // Assert
        XCTAssertFalse(sut.isEmpty)
    }

    func test_loadFavorites_whenNoFavoritesLocally_itemsAreEmpty() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 1), Gift.make(id: 2)]
        favoritesService.favoriteIds = [] // нет избранных

        // Act
        await awaitLoad { self.sut.loadFavorites() }

        // Assert
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertTrue(sut.isEmpty)
    }

    func test_loadFavorites_filtersGiftsByLocalFavoriteIds() async {
        // Arrange — в репозитории 3 подарка, в избранном только 2
        repository.stubbedGifts = [Gift.make(id: 1), Gift.make(id: 2), Gift.make(id: 3)]
        favoritesService.favoriteIds = [1, 3]

        // Act
        await awaitLoad { self.sut.loadFavorites() }

        // Assert
        XCTAssertEqual(sut.items.count, 2)
        XCTAssertTrue(sut.items.contains(where: { $0.id == 1 }))
        XCTAssertTrue(sut.items.contains(where: { $0.id == 3 }))
        XCTAssertFalse(sut.items.contains(where: { $0.id == 2 }))
    }

    // MARK: - removeFromFavorites

    func test_removeFromFavorites_immediatelyRemovesItemFromList() async {
        // Arrange — загружаем подарки
        repository.stubbedGifts = [Gift.make(id: 1), Gift.make(id: 2)]
        favoritesService.favoriteIds = [1, 2]
        await awaitLoad { self.sut.loadFavorites() }

        // Act
        let stateExpectation = expectation(description: "state changed after remove")
        stateExpectation.assertForOverFulfill = false
        sut.onStateChanged = { stateExpectation.fulfill() }
        sut.removeFromFavorites(1)

        await fulfillment(of: [stateExpectation], timeout: 1.0)

        // Assert
        XCTAssertFalse(sut.items.contains(where: { $0.id == 1 }))
        XCTAssertEqual(sut.items.count, 1)
    }

    func test_removeFromFavorites_updatesIsEmpty_whenLastItemRemoved() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 1)]
        favoritesService.favoriteIds = [1]
        await awaitLoad { self.sut.loadFavorites() }

        // Act
        let stateExpectation = expectation(description: "state changed")
        stateExpectation.assertForOverFulfill = false
        sut.onStateChanged = { stateExpectation.fulfill() }
        sut.removeFromFavorites(1)

        await fulfillment(of: [stateExpectation], timeout: 1.0)

        // Assert
        XCTAssertTrue(sut.isEmpty)
    }

    func test_removeFromFavorites_callsOnRemovalPending() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 5)]
        favoritesService.favoriteIds = [5]
        await awaitLoad { self.sut.loadFavorites() }

        var pendingGiftId: Int?
        sut.onRemovalPending = { id in pendingGiftId = id }

        // Act
        let stateExpectation = expectation(description: "state changed")
        stateExpectation.assertForOverFulfill = false
        sut.onStateChanged = { stateExpectation.fulfill() }
        sut.removeFromFavorites(5)

        await fulfillment(of: [stateExpectation], timeout: 1.0)

        // Assert
        XCTAssertEqual(pendingGiftId, 5)
    }

    func test_removeFromFavorites_withNonExistentId_doesNothing() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 1)]
        favoritesService.favoriteIds = [1]
        await awaitLoad { self.sut.loadFavorites() }

        let countBefore = sut.items.count

        // Act — удаляем несуществующий id
        sut.removeFromFavorites(999)

        // Assert — список не изменился
        XCTAssertEqual(sut.items.count, countBefore)
    }

    // MARK: - undoRemoval

    func test_undoRemoval_restoresRemovedGift() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 3)]
        favoritesService.favoriteIds = [3]
        await awaitLoad { self.sut.loadFavorites() }

        // Удаляем
        let removeExpectation = expectation(description: "removed")
        removeExpectation.assertForOverFulfill = false
        sut.onStateChanged = { removeExpectation.fulfill() }
        sut.removeFromFavorites(3)
        await fulfillment(of: [removeExpectation], timeout: 1.0)

        // Act — отменяем удаление
        let undoExpectation = expectation(description: "undo applied")
        undoExpectation.assertForOverFulfill = false
        sut.onStateChanged = { undoExpectation.fulfill() }
        sut.undoRemoval(of: 3)

        await fulfillment(of: [undoExpectation], timeout: 1.0)

        // Assert
        XCTAssertTrue(sut.items.contains(where: { $0.id == 3 }))
    }

    func test_undoRemoval_restoresIsEmptyToFalse() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 3)]
        favoritesService.favoriteIds = [3]
        await awaitLoad { self.sut.loadFavorites() }

        let removeExpectation = expectation(description: "removed")
        removeExpectation.assertForOverFulfill = false
        sut.onStateChanged = { removeExpectation.fulfill() }
        sut.removeFromFavorites(3)
        await fulfillment(of: [removeExpectation], timeout: 1.0)
        XCTAssertTrue(sut.isEmpty)

        // Act
        let undoExpectation = expectation(description: "undo")
        undoExpectation.assertForOverFulfill = false
        sut.onStateChanged = { undoExpectation.fulfill() }
        sut.undoRemoval(of: 3)
        await fulfillment(of: [undoExpectation], timeout: 1.0)

        // Assert
        XCTAssertFalse(sut.isEmpty)
    }

    func test_undoRemoval_withUnknownId_doesNotCrash() {
        // Arrange / Act / Assert — просто не должно упасть
        XCTAssertNoThrow(sut.undoRemoval(of: 999))
    }
}
