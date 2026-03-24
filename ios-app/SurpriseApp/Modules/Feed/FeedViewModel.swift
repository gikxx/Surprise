import Foundation

// MARK: - FeedViewModelProtocol
protocol FeedViewModelProtocol: AnyObject {
    var gifts: [Gift] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isEmpty: Bool { get }
    var categories: [String] { get }
    var selectedCategoryIndex: Int { get }
    
    func loadInitial()
    func loadCategories() async
    func toggleFavorite(for giftId: Int)
    func searchGifts(query: String)
    func selectCategory(at index: Int)
    func filterByCategory(_ category: String)
    func refreshFavoritesState()
}

protocol PaginatableFeedViewModelProtocol: FeedViewModelProtocol {
    var canLoadMore: Bool { get }
    func loadMoreIfNeeded(currentIndex: Int)
}

// MARK: - FeedViewModel
final class FeedViewModel: FeedViewModelProtocol {
    
    // MARK: - Properties
    private(set) var gifts: [Gift] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String? = nil
    private(set) var isEmpty: Bool = false
    private(set) var canLoadMore: Bool = false
    private(set) var selectedCategoryIndex: Int = 0
    private(set) var categories: [String] = []
    
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
            let fetchedCategories = try await repository.getCategories()
            await MainActor.run {
                self.categories = ["все"] + fetchedCategories
                self.onStateChanged?()
            }
        } catch {
            print("❌ Failed to load categories: \(error)")
            await MainActor.run {
                self.categories = ["все"]
                self.onStateChanged?()
            }
        }
    }
    
    func loadInitial() {
        updateGiftsState([], isLoading: true)
        
        Task {
            if categories.isEmpty {
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
        filterByCategory(categories[index])
    }
    
    func loadMoreIfNeeded(currentIndex: Int) {
        guard canLoadMore, !isLoadingMore else { return }
        // Пока заглушка для пагинации
    }
    
    func refreshFavoritesState() {
        let updatedGifts = applyFavoritesState(to: allGifts)
        updateGiftsState(updatedGifts)
    }
    
    func toggleFavorite(for giftId: Int) {
        Task {
                do {
                    try await favoritesService.toggleFavorite(id: giftId)
                    let updated = gifts.map { gift -> Gift in
                        var copy = gift
                        if gift.id == giftId {
                            copy.isFavorite = favoritesService.isFavorite(id: giftId)
                        }
                        return copy
                    }
                    await MainActor.run {
                        updateGiftsState(updated)
                        self.allGifts = updated
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
    
    func filterByCategory(_ category: String) {
        if category == "все" {
            updateGiftsState(allGifts)
            return
        }
        
        Task {
            do {
                let rawResults = try await repository.getByCategory(category)
                let results = applyFavoritesState(to: rawResults)
                await MainActor.run {
                    updateGiftsState(results)
                }
            } catch {
                await MainActor.run {
                    let localResults = allGifts.filter { $0.categories.contains(category) }
                    updateGiftsState(localResults)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
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
