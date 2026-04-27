import Foundation

// MARK: - FeedViewModelProtocol
protocol FeedViewModelProtocol: AnyObject {
    var gifts: [Gift] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isEmpty: Bool { get }

    /// Display-имена категорий для UI: первый элемент — "все", далее
    /// идут имена категорий с бэка. View не должна знать о category_id.
    var categories: [String] { get }
    var selectedCategoryIndex: Int { get }

    func loadInitial()
    func loadCategories() async
    func toggleFavorite(for giftId: Int)
    func searchGifts(query: String)
    func selectCategory(at index: Int)
    func refreshFavoritesState()
}

protocol PaginatableFeedViewModelProtocol: FeedViewModelProtocol {
    var canLoadMore: Bool { get }
    func loadMoreIfNeeded(currentIndex: Int)
}

// MARK: - FeedViewModel
final class FeedViewModel: FeedViewModelProtocol {

    // MARK: - Constants

    /// Значение, которое отображается в первой ячейке чипсов и означает
    /// "снять фильтр". На бэк не уходит — фильтр по категории — это просто
    /// отсутствие параметра category_id.
    private static let allCategoriesTitle = "все"

    // MARK: - Properties
    private(set) var gifts: [Gift] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String? = nil
    private(set) var isEmpty: Bool = false
    private(set) var canLoadMore: Bool = false
    private(set) var selectedCategoryIndex: Int = 0

    /// Источник правды: список категорий с бэка (без "все").
    /// Индекс i в этом массиве == индекс (i + 1) в `categories`.
    private var availableCategories: [Category] = []

    /// Display-имена для View, всегда начинается с "все".
    var categories: [String] {
        [Self.allCategoriesTitle] + availableCategories.map { $0.name }
    }

    private let repository: GiftRepositoryProtocol
    private let favoritesService: FavoritesServiceProtocol
    private var allGifts: [Gift] = []

    private var isLoadingMore: Bool = false

    // MARK: - Callbacks
    var onStateChanged: (() -> Void)?

    // MARK: - Init
    init(
        repository: GiftRepositoryProtocol,
        favoritesService: FavoritesServiceProtocol = FavoritesService()
    ) {
        self.repository = repository
        self.favoritesService = favoritesService
    }

    // MARK: - Public Methods

    func loadCategories() async {
        do {
            let fetched = try await repository.getCategories()
            await MainActor.run {
                self.availableCategories = fetched
                self.onStateChanged?()
            }
        } catch {
            #if DEBUG
            print("❌ Failed to load categories: \(error)")
            #endif
            await MainActor.run {
                self.availableCategories = []
                self.onStateChanged?()
            }
        }
    }

    func loadInitial() {
        updateGiftsState([], isLoading: true)

        Task {
            // Перед тем как раскрашивать сердечки, подтянем актуальные favorites
            // с сервера. Без этого локальный UserDefaults-кэш мог остаться от
            // прошлой сессии (или быть пустым на свежем запуске), и Лента
            // показывала бы инверсное состояние относительно сервера.
            try? await favoritesService.syncFromServer()

            if availableCategories.isEmpty {
                await loadCategories()
            }

            do {
                let recommendedGifts = try await repository.getRecommendedGifts()
                let giftsWithFavorites = applyFavoritesState(to: recommendedGifts)
                await MainActor.run {
                    updateGiftsState(giftsWithFavorites)
                    self.allGifts = giftsWithFavorites
                    self.canLoadMore = false
                }
            } catch {
                AnalyticsService.shared.logCriticalError(scenario: "load_initial", error: error)
                await MainActor.run {
                    updateGiftsState([], isLoading: false, error: "Не удалось загрузить подарки")
                    self.canLoadMore = false
                }
            }
        }
    }

    func selectCategory(at index: Int) {
        guard index >= 0 && index < categories.count else { return }
        selectedCategoryIndex = index

        if index == 0 {
            // "все" — никакой фильтрации, показываем закешированный allGifts
            updateGiftsState(allGifts)
            return
        }

        let category = availableCategories[index - 1]
        loadGifts(filteredBy: category)
    }

    func loadMoreIfNeeded(currentIndex: Int) {
        guard canLoadMore, !isLoadingMore else { return }
        // Пока заглушка для пагинации
    }

    func refreshFavoritesState() {
        // Вызывается из viewWillAppear — это лучший момент, чтобы догнать
        // локальный кэш до состояния сервера (например, если юзер успел
        // полайкать через GiftDetailViewController на другом экране).
        Task {
            try? await favoritesService.syncFromServer()
            await MainActor.run {
                let updatedGifts = self.applyFavoritesState(to: self.allGifts)
                self.updateGiftsState(updatedGifts)
            }
        }
    }

    func toggleFavorite(for giftId: Int) {
        Task {
            do {
                try await favoritesService.toggleFavorite(id: giftId)
                let newIsFavorite = favoritesService.isFavorite(id: giftId)

                // Точечно обновляем isFavorite в обеих коллекциях, не подменяя
                // их целиком. Раньше self.allGifts = updated затирал «всё»
                // отфильтрованной выборкой, и после тапа «все» возвращалась
                // только текущая категория.
                let updatedDisplayed = self.gifts.map { gift -> Gift in
                    var copy = gift
                    if gift.id == giftId { copy.isFavorite = newIsFavorite }
                    return copy
                }
                let updatedAll = self.allGifts.map { gift -> Gift in
                    var copy = gift
                    if gift.id == giftId { copy.isFavorite = newIsFavorite }
                    return copy
                }

                await MainActor.run {
                    self.allGifts = updatedAll
                    updateGiftsState(updatedDisplayed)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Не удалось обновить избранное"
                    onStateChanged?()
                }
            }
        }
    }

    func searchGifts(query: String) {
        if query.isEmpty {
            updateGiftsState(allGifts)
            return
        }

        Task {
            do {
                let rawResults = try await repository.search(query: query)
                let results = applyFavoritesState(to: rawResults)
                await MainActor.run {
                    updateGiftsState(results)
                }
            } catch {
                await MainActor.run {
                    let localResults = allGifts.filter {
                        $0.name.lowercased().contains(query.lowercased()) ||
                        $0.description?.lowercased().contains(query.lowercased()) == true
                    }
                    updateGiftsState(localResults)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func loadGifts(filteredBy category: Category) {
        Task {
            do {
                let rawResults = try await repository.getByCategory(id: category.id)
                let results = applyFavoritesState(to: rawResults)
                await MainActor.run {
                    updateGiftsState(results)
                }
            } catch {
                AnalyticsService.shared.logCriticalError(
                    scenario: "filter_by_category",
                    error: error,
                    parameters: ["category_id": category.id, "category_name": category.name]
                )
                await MainActor.run {
                    let localResults = allGifts.filter { gift in
                        gift.categories.contains(where: { $0.id == category.id })
                    }
                    updateGiftsState(localResults)
                }
            }
        }
    }

    private func updateGiftsState(_ gifts: [Gift], isLoading: Bool = false, error: String? = nil) {
        self.gifts = gifts
        self.isLoading = isLoading
        self.errorMessage = error
        self.isEmpty = gifts.isEmpty
        self.onStateChanged?()
    }

    private func applyFavoritesState(to gifts: [Gift]) -> [Gift] {
        let favoriteIds = favoritesService.getFavoriteIds()

        return gifts.map { gift in
            var copy = gift
            copy.isFavorite = favoriteIds.contains(gift.id)
            return copy
        }
    }
}
