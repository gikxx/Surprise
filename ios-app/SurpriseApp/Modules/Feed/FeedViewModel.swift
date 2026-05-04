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

    /// Текущий активный фильтр бюджета.
    var activeBudgetFilter: BudgetFilter { get }

    func loadInitial()
    func loadCategories() async
    func toggleFavorite(for giftId: Int)
    func searchGifts(query: String)
    func selectCategory(at index: Int)
    func refreshFavoritesState()

    /// Установить фильтр бюджета и обновить отображаемую ленту.
    func setBudgetFilter(_ filter: BudgetFilter)
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

    /// Полный список подарков без бюджетного фильтра (кэш для «все»).
    private var allGifts: [Gift] = []

    /// Подарки текущей категории до применения бюджетного фильтра.
    /// При «все» совпадает с allGifts.
    private var categoryGifts: [Gift] = []

    /// Активный фильтр бюджета. Применяется поверх категорийного фильтра.
    private(set) var activeBudgetFilter: BudgetFilter = .any

    private var isLoadingMore: Bool = false

    // MARK: - Callbacks
    var onStateChanged: (() -> Void)?
    /// Вызывается только при лайке — без полной перезагрузки коллекции.
    var onFavoriteToggled: ((Int, Bool) -> Void)?

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
            // Все три запроса не зависят друг от друга — пускаем параллельно
            // вместо строгого await-await-await. На холодном старте это
            // главное, что убирает «застывший» спиннер.
            async let favoritesSyncResult: Void = {
                _ = try? await favoritesService.syncFromServer()
            }()

            async let categoriesResult: Void = {
                if await self.availableCategories.isEmpty {
                    await self.loadCategories()
                }
            }()

            async let recommendedResult: Result<[Gift], Error> = {
                do {
                    let gifts = try await repository.getRecommendedGifts()
                    return .success(gifts)
                } catch {
                    return .failure(error)
                }
            }()

            // Дожидаемся всех. favorites/categories — fire-and-forget по сути,
            // recommended — единственный, чей результат блокирует UI.
            _ = await favoritesSyncResult
            _ = await categoriesResult
            let result = await recommendedResult

            switch result {
            case .success(let recommendedGifts):
                let giftsWithFavorites = applyFavoritesState(to: recommendedGifts)
                await MainActor.run {
                    self.allGifts = giftsWithFavorites
                    self.categoryGifts = giftsWithFavorites
                    self.updateGiftsState(self.applyBudgetFilter(giftsWithFavorites))
                    self.canLoadMore = false
                }
            case .failure(let error):
                AnalyticsService.shared.logCriticalError(scenario: "load_initial", error: error)
                await MainActor.run {
                    self.updateGiftsState([], isLoading: false, error: "Не удалось загрузить подарки")
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
            categoryGifts = allGifts
            updateGiftsState(applyBudgetFilter(allGifts))
            return
        }

        let category = availableCategories[index - 1]
        loadGifts(filteredBy: category)
    }

    func setBudgetFilter(_ filter: BudgetFilter) {
        activeBudgetFilter = filter
        // Переприменяем к базовому списку текущей категории
        updateGiftsState(applyBudgetFilter(categoryGifts))
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
                self.allGifts = updatedGifts
                // categoryGifts — тоже обновляем favorites, не трогая фильтр
                let updatedCategory = self.applyFavoritesState(to: self.categoryGifts)
                self.categoryGifts = updatedCategory
                self.updateGiftsState(self.applyBudgetFilter(updatedCategory))
            }
        }
    }

    func toggleFavorite(for giftId: Int) {
        Task {
            do {
                try await favoritesService.toggleFavorite(id: giftId)

                // isFavorite читаем на MainActor — для гостей toggleFavorite
                // обновляет favoriteIds через MainActor.run, и чтение из
                // фонового потока может поймать гонку (стale значение).
                await MainActor.run {
                    let newIsFavorite = self.favoritesService.isFavorite(id: giftId)

                    // Точечно обновляем isFavorite в обеих коллекциях, не подменяя
                    // их целиком.
                    self.gifts = self.gifts.map { gift -> Gift in
                        var copy = gift
                        if gift.id == giftId { copy.isFavorite = newIsFavorite }
                        return copy
                    }
                    self.allGifts = self.allGifts.map { gift -> Gift in
                        var copy = gift
                        if gift.id == giftId { copy.isFavorite = newIsFavorite }
                        return copy
                    }
                    self.categoryGifts = self.categoryGifts.map { gift -> Gift in
                        var copy = gift
                        if gift.id == giftId { copy.isFavorite = newIsFavorite }
                        return copy
                    }

                    // Не вызываем onStateChanged — коллекцию не перезагружаем
                    self.onFavoriteToggled?(giftId, newIsFavorite)
                    Toast.show(
                        newIsFavorite
                            ? "Подарок добавлен в избранное"
                            : "Подарок убран из избранного"
                    )
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Не удалось обновить избранное"
                    onStateChanged?()
                    Toast.show("Не удалось обновить избранное")
                }
            }
        }
    }

    func searchGifts(query: String) {
        if query.isEmpty {
            updateGiftsState(applyBudgetFilter(categoryGifts))
            return
        }

        Task {
            do {
                let rawResults = try await repository.search(query: query)
                let results = applyFavoritesState(to: rawResults)
                await MainActor.run {
                    updateGiftsState(self.applyBudgetFilter(results))
                }
            } catch {
                await MainActor.run {
                    let localResults = self.categoryGifts.filter {
                        $0.name.lowercased().contains(query.lowercased()) ||
                        $0.description?.lowercased().contains(query.lowercased()) == true
                    }
                    updateGiftsState(self.applyBudgetFilter(localResults))
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
                    self.categoryGifts = results
                    updateGiftsState(self.applyBudgetFilter(results))
                }
            } catch {
                AnalyticsService.shared.logCriticalError(
                    scenario: "filter_by_category",
                    error: error,
                    parameters: ["category_id": category.id, "category_name": category.name]
                )
                await MainActor.run {
                    let localResults = self.allGifts.filter { gift in
                        gift.categories.contains(where: { $0.id == category.id })
                    }
                    self.categoryGifts = localResults
                    updateGiftsState(self.applyBudgetFilter(localResults))
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

    /// Применяет активный бюджетный фильтр к списку подарков.
    private func applyBudgetFilter(_ gifts: [Gift]) -> [Gift] {
        activeBudgetFilter.apply(to: gifts)
    }
}
