import XCTest
@testable import SurpriseApp

// MARK: - BudgetFilterTests

final class BudgetFilterTests: XCTestCase {

    // MARK: - isActive

    func test_isActive_withAnyFilter_returnsFalse() {
        // Arrange
        let filter = BudgetFilter.any

        // Act
        let result = filter.isActive

        // Assert
        XCTAssertFalse(result)
    }

    func test_isActive_withCustomMinPrice_returnsTrue() {
        // Arrange
        let filter = BudgetFilter(minPrice: 1000, maxPrice: BudgetFilter.sliderMax)

        // Act
        let result = filter.isActive

        // Assert
        XCTAssertTrue(result)
    }

    func test_isActive_withCustomMaxPrice_returnsTrue() {
        // Arrange
        let filter = BudgetFilter(minPrice: 0, maxPrice: 10_000)

        // Act
        let result = filter.isActive

        // Assert
        XCTAssertTrue(result)
    }

    func test_isActive_withBothBoundsSet_returnsTrue() {
        // Arrange
        let filter = BudgetFilter(minPrice: 5_000, maxPrice: 20_000)

        // Act
        let result = filter.isActive

        // Assert
        XCTAssertTrue(result)
    }

    // MARK: - chipLabel

    func test_chipLabel_withMinZeroAndMaxAtSliderMax_returnsEmptyString() {
        // Arrange — "any" состояние, chipLabel не используется, но поведение должно быть предсказуемым
        let filter = BudgetFilter(minPrice: 0, maxPrice: BudgetFilter.sliderMax)

        // Act
        let label = filter.chipLabel

        // Assert
        XCTAssertEqual(label, "")
    }

    func test_chipLabel_withOnlyMinPrice_returnsFromLabel() {
        // Arrange
        let filter = BudgetFilter(minPrice: 5_000, maxPrice: BudgetFilter.sliderMax)

        // Act
        let label = filter.chipLabel

        // Assert
        XCTAssertTrue(label.hasPrefix("от"), "Ожидался лейбл начинающийся с 'от', получили: \(label)")
        XCTAssertTrue(label.hasSuffix("₽"), "Ожидался лейбл заканчивающийся на '₽', получили: \(label)")
    }

    func test_chipLabel_withBothBounds_returnsRangeLabel() {
        // Arrange
        let filter = BudgetFilter(minPrice: 1_000, maxPrice: 10_000)

        // Act
        let label = filter.chipLabel

        // Assert
        XCTAssertTrue(label.contains("–"), "Ожидался разделитель '–' в диапазоне, получили: \(label)")
        XCTAssertTrue(label.hasSuffix("₽"), "Ожидался лейбл заканчивающийся на '₽', получили: \(label)")
    }

    // MARK: - apply(to:)

    func test_apply_withAnyFilter_returnsAllGifts() {
        // Arrange
        let gifts = [
            Gift.make(id: 1, price: 500),
            Gift.make(id: 2, price: 5_000),
            Gift.make(id: 3, price: 50_000),
            Gift.make(id: 4, price: 100_000)
        ]
        let filter = BudgetFilter.any

        // Act
        let result = filter.apply(to: gifts)

        // Assert
        XCTAssertEqual(result.count, gifts.count)
    }

    func test_apply_withMinPriceFilter_excludesCheaperGifts() {
        // Arrange
        let gifts = [
            Gift.make(id: 1, price: 500),
            Gift.make(id: 2, price: 1_000),
            Gift.make(id: 3, price: 5_000)
        ]
        let filter = BudgetFilter(minPrice: 1_000, maxPrice: BudgetFilter.sliderMax)

        // Act
        let result = filter.apply(to: gifts)

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.price >= 1_000 })
    }

    func test_apply_withMaxPriceFilter_excludesMoreExpensiveGifts() {
        // Arrange
        let gifts = [
            Gift.make(id: 1, price: 500),
            Gift.make(id: 2, price: 5_000),
            Gift.make(id: 3, price: 20_000)
        ]
        let filter = BudgetFilter(minPrice: 0, maxPrice: 10_000)

        // Act
        let result = filter.apply(to: gifts)

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.price <= 10_000 })
    }

    func test_apply_withBothBounds_returnsOnlyGiftsInRange() {
        // Arrange
        let gifts = [
            Gift.make(id: 1, price: 500),
            Gift.make(id: 2, price: 3_000),
            Gift.make(id: 3, price: 7_000),
            Gift.make(id: 4, price: 15_000)
        ]
        let filter = BudgetFilter(minPrice: 2_000, maxPrice: 10_000)

        // Act
        let result = filter.apply(to: gifts)

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.map { $0.id }, [2, 3])
    }

    func test_apply_withExactBoundaryPrice_includesGift() {
        // Arrange — граничный случай: цена ровно равна minPrice и maxPrice
        let gifts = [
            Gift.make(id: 1, price: 2_000),
            Gift.make(id: 2, price: 10_000)
        ]
        let filter = BudgetFilter(minPrice: 2_000, maxPrice: 10_000)

        // Act
        let result = filter.apply(to: gifts)

        // Assert
        XCTAssertEqual(result.count, 2, "Подарки с ценой ровно на границе должны включаться в результат")
    }

    func test_apply_withEmptyGiftList_returnsEmptyList() {
        // Arrange
        let gifts: [Gift] = []
        let filter = BudgetFilter(minPrice: 1_000, maxPrice: 5_000)

        // Act
        let result = filter.apply(to: gifts)

        // Assert
        XCTAssertTrue(result.isEmpty)
    }

    func test_apply_withNoGiftsMatchingFilter_returnsEmptyList() {
        // Arrange
        let gifts = [
            Gift.make(id: 1, price: 100),
            Gift.make(id: 2, price: 200)
        ]
        let filter = BudgetFilter(minPrice: 10_000, maxPrice: BudgetFilter.sliderMax)

        // Act
        let result = filter.apply(to: gifts)

        // Assert
        XCTAssertTrue(result.isEmpty)
    }

    func test_apply_withMaxAtSliderMax_includesGiftsAboveSliderMax() {
        // Arrange — sliderMax означает «нет верхней границы»
        let gifts = [
            Gift.make(id: 1, price: 40_000),
            Gift.make(id: 2, price: 50_000),
            Gift.make(id: 3, price: 100_000)
        ]
        let filter = BudgetFilter(minPrice: 0, maxPrice: BudgetFilter.sliderMax)

        // Act
        let result = filter.apply(to: gifts)

        // Assert — без верхней границы должны вернуться все 3 подарка
        XCTAssertEqual(result.count, 3)
    }
}
