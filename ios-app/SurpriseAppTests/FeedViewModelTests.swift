import XCTest
@testable import SurpriseApp

// MARK: - FeedViewModelTests

@MainActor
final class FeedViewModelTests: XCTestCase {

    private var repository: MockGiftRepository!
    private var favoritesService: MockFavoritesService!
    private var sut: FeedViewModel!

    override func setUp() {
        super.setUp()
        repository = MockGiftRepository()
        favoritesService = MockFavoritesService()
        sut = FeedViewModel(repository: repository, favoritesService: favoritesService)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        favoritesService = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Выставляет onStateChanged ДО вызова action, затем ждёт первого
    /// коллбэка при котором isLoading == false.
    private func awaitLoad(timeout: TimeInterval = 3.0, action: () -> Void) async {
        let exp = expectation(description: "loading finished")
        exp.assertForOverFulfill = false
        sut.onStateChanged = { [weak self] in
            guard let self, !self.sut.isLoading else { return }
            exp.fulfill()
        }
        action()
        await fulfillment(of: [exp], timeout: timeout)
    }

    /// Выставляет onStateChanged ДО вызова action, ждёт любого коллбэка.
    private func awaitChange(timeout: TimeInterval = 2.0, action: () -> Void) async {
        let exp = expectation(description: "state changed")
        exp.assertForOverFulfill = false
        sut.onStateChanged = { exp.fulfill() }
        action()
        await fulfillment(of: [exp], timeout: timeout)
    }

    // MARK: - loadInitial — успешная загрузка

    func test_loadInitial_withGifts_populatesGiftsArray() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 1), Gift.make(id: 2)]

        // Act
        await awaitLoad { self.sut.loadInitial() }

        // Assert
        XCTAssertEqual(sut.gifts.count, 2)
    }

    func test_loadInitial_withGifts_setsIsLoadingFalse() async {
        // Arrange
        repository.stubbedGifts = [Gift.make()]

        // Act
        await awaitLoad { self.sut.loadInitial() }

        // Assert
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadInitial_withGifts_clearsErrorMessage() async {
        // Arrange
        repository.stubbedGifts = [Gift.make()]

        // Act
        await awaitLoad { self.sut.loadInitial() }

        // Assert
        XCTAssertNil(sut.errorMessage)
    }

    func test_loadInitial_withEmptyGifts_setsIsEmptyTrue() async {
        // Arrange
        repository.stubbedGifts = []

        // Act
        await awaitLoad { self.sut.loadInitial() }

        // Assert
        XCTAssertTrue(sut.isEmpty)
    }

    // MARK: - loadInitial — ошибка сети

    func test_loadInitial_whenRepositoryThrows_setsErrorMessage() async {
        // Arrange
        repository.shouldThrow = true

        // Act
        await awaitLoad { self.sut.loadInitial() }

        // Assert
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_loadInitial_whenRepositoryThrows_giftsArrayIsEmpty() async {
        // Arrange
        repository.shouldThrow = true

        // Act
        await awaitLoad { self.sut.loadInitial() }

        // Assert
        XCTAssertTrue(sut.gifts.isEmpty)
    }

    // MARK: - categories

    func test_categories_alwaysStartsWithAllCategoriesTitle() async {
        // Arrange
        repository.stubbedCategories = [
            SurpriseApp.Category(id: 1, name: "Для неё"),
            SurpriseApp.Category(id: 2, name: "Для него")
        ]

        // Act
        await awaitLoad { self.sut.loadInitial() }

        // Assert
        XCTAssertEqual(sut.categories.first, "все")
    }

    func test_categories_includesLoadedCategoryNames() async {
        // Arrange
        repository.stubbedCategories = [
            SurpriseApp.Category(id: 1, name: "Для неё"),
            SurpriseApp.Category(id: 2, name: "Для него")
        ]

        // Act
        await awaitLoad { self.sut.loadInitial() }

        // Assert
        XCTAssertTrue(sut.categories.contains("Для неё"))
        XCTAssertTrue(sut.categories.contains("Для него"))
    }

    // MARK: - selectCategory

    func test_selectCategory_atIndexZero_showsAllGifts() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 1), Gift.make(id: 2), Gift.make(id: 3)]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitChange { self.sut.selectCategory(at: 0) }

        // Assert
        XCTAssertEqual(sut.gifts.count, 3)
        XCTAssertEqual(sut.selectedCategoryIndex, 0)
    }

    func test_selectCategory_atCategoryIndex_callsRepositoryGetByCategory() async {
        // Arrange
        let category = SurpriseApp.Category(id: 42, name: "Для неё")
        repository.stubbedCategories = [category]
        repository.stubbedGifts = [Gift.make(id: 1, categories: [category])]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitLoad { self.sut.selectCategory(at: 1) }

        // Assert
        XCTAssertEqual(repository.getByCategoryCalledWithId, 42)
    }

    func test_selectCategory_withOutOfBoundsIndex_doesNotCrash() async {
        // Arrange
        await awaitLoad { self.sut.loadInitial() }

        // Act & Assert
        XCTAssertNoThrow(sut.selectCategory(at: 999))
        XCTAssertNoThrow(sut.selectCategory(at: -1))
    }

    // MARK: - setBudgetFilter

    func test_setBudgetFilter_withActiveFilter_filtersGiftsByPrice() async {
        // Arrange
        repository.stubbedGifts = [
            Gift.make(id: 1, price: 500),
            Gift.make(id: 2, price: 5_000),
            Gift.make(id: 3, price: 20_000)
        ]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitChange { self.sut.setBudgetFilter(BudgetFilter(minPrice: 1_000, maxPrice: 10_000)) }

        // Assert
        XCTAssertEqual(sut.gifts.count, 1)
        XCTAssertEqual(sut.gifts.first?.id, 2)
    }

    func test_setBudgetFilter_withAnyFilter_returnsAllGifts() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 1, price: 500), Gift.make(id: 2, price: 50_000)]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitChange { self.sut.setBudgetFilter(.any) }

        // Assert
        XCTAssertEqual(sut.gifts.count, 2)
    }

    func test_setBudgetFilter_setsActiveBudgetFilter() async {
        // Arrange
        repository.stubbedGifts = [Gift.make()]
        await awaitLoad { self.sut.loadInitial() }
        let filter = BudgetFilter(minPrice: 2_000, maxPrice: 15_000)

        // Act
        await awaitChange { self.sut.setBudgetFilter(filter) }

        // Assert
        XCTAssertEqual(sut.activeBudgetFilter, filter)
    }

    // MARK: - searchGifts

    func test_searchGifts_withEmptyQuery_restoresCategoryGifts() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 1), Gift.make(id: 2)]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitChange { self.sut.searchGifts(query: "") }

        // Assert
        XCTAssertEqual(sut.gifts.count, 2)
    }

    func test_searchGifts_withNonEmptyQuery_callsRepositorySearch() async {
        // Arrange
        repository.stubbedSearchResults = [Gift.make(id: 99, name: "Ёжик")]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitLoad { self.sut.searchGifts(query: "Ёжик") }

        // Assert
        XCTAssertEqual(repository.searchCalledWithQuery, "Ёжик")
    }

    func test_searchGifts_withNonEmptyQuery_updatesGiftsWithSearchResults() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 1), Gift.make(id: 2)]
        repository.stubbedSearchResults = [Gift.make(id: 99, name: "Ёжик")]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitLoad { self.sut.searchGifts(query: "Ёжик") }

        // Assert
        XCTAssertEqual(sut.gifts.count, 1)
        XCTAssertEqual(sut.gifts.first?.id, 99)
    }

    // MARK: - toggleFavorite

    func test_toggleFavorite_callsFavoritesService() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 7)]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitChange { self.sut.toggleFavorite(for: 7) }

        // Assert
        XCTAssertEqual(favoritesService.toggleCalledWithId, 7)
    }

    func test_toggleFavorite_updatesIsFavoriteInGiftsArray() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 7, isFavorite: false)]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitChange { self.sut.toggleFavorite(for: 7) }

        // Assert
        XCTAssertEqual(sut.gifts.first(where: { $0.id == 7 })?.isFavorite, true)
    }

    func test_toggleFavorite_whenServiceThrows_setsErrorMessage() async {
        // Arrange
        favoritesService.shouldThrow = true
        repository.stubbedGifts = [Gift.make(id: 1)]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitChange { self.sut.toggleFavorite(for: 1) }

        // Assert
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - refreshFavoritesState

    func test_refreshFavoritesState_callsSyncFromServer() async {
        // Arrange
        repository.stubbedGifts = [Gift.make()]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitChange { self.sut.refreshFavoritesState() }

        // Assert
        XCTAssertTrue(favoritesService.syncCalled)
    }

    func test_refreshFavoritesState_updatesFavoriteStatusFromService() async {
        // Arrange
        repository.stubbedGifts = [Gift.make(id: 5, isFavorite: false)]
        favoritesService.favoriteIds = [5]
        await awaitLoad { self.sut.loadInitial() }

        // Act
        await awaitChange { self.sut.refreshFavoritesState() }

        // Assert
        XCTAssertEqual(sut.gifts.first(where: { $0.id == 5 })?.isFavorite, true)
    }
}
