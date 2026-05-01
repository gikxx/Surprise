import Foundation
@testable import SurpriseApp

// MARK: - MockNetworkService

final class MockNetworkService: NetworkServiceProtocol {

    var stubbedData: Data?
    var shouldThrow: Bool = false
    var stubError: Error = URLError(.notConnectedToInternet)

    private(set) var lastEndpoint: Endpoint?
    private(set) var requestVoidCalled = false
    private(set) var requestVoidCalledCount = 0

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        lastEndpoint = endpoint
        if shouldThrow { throw stubError }
        guard let data = stubbedData else { throw NetworkError.noData }
        return try decoder.decode(T.self, from: data)
    }

    func requestVoid(_ endpoint: Endpoint) async throws {
        lastEndpoint = endpoint
        requestVoidCalled = true
        requestVoidCalledCount += 1
        if shouldThrow { throw stubError }
    }
}

// MARK: - MockGiftLocalDataSource

final class MockGiftLocalDataSource: GiftLocalDataSourceProtocol {
    var stubbedGifts: [Gift] = []
    var stubbedCategories: [SurpriseApp.Category] = []
    var stubbedSearchResults: [Gift] = []
    var shouldThrow: Bool = false

    private(set) var fetchGiftsCalled = false
    private(set) var searchCalledWithQuery: String?
    private(set) var fetchCategoriesCalled = false

    func fetchGifts() async throws -> [Gift] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        fetchGiftsCalled = true
        return stubbedGifts
    }

    func search(query: String) async throws -> [Gift] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        searchCalledWithQuery = query
        return stubbedSearchResults
    }

    func fetchCategories() async throws -> [SurpriseApp.Category] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        fetchCategoriesCalled = true
        return stubbedCategories
    }
}

// MARK: - MockGiftRemoteDataSource

final class MockGiftRemoteDataSource: GiftRemoteDataSourceProtocol {
    var stubbedGifts: [Gift] = []
    var stubbedCategories: [SurpriseApp.Category] = []
    var shouldThrow: Bool = false

    private(set) var fetchAllCalled = false
    private(set) var fetchRecommendedCalled = false
    private(set) var fetchByCategoryCalledWithId: Int?
    private(set) var searchCalledWithQuery: String?
    private(set) var fetchCategoriesCalled = false

    func fetchAll(page: Int, perPage: Int) async throws -> [Gift] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        fetchAllCalled = true
        return stubbedGifts
    }

    func fetchRecommended(page: Int, perPage: Int) async throws -> [Gift] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        fetchRecommendedCalled = true
        return stubbedGifts
    }

    func search(query: String, page: Int, perPage: Int) async throws -> [Gift] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        searchCalledWithQuery = query
        return stubbedGifts
    }

    func fetchByCategory(id: Int, page: Int, perPage: Int) async throws -> [Gift] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        fetchByCategoryCalledWithId = id
        return stubbedGifts
    }

    func fetchCategories() async throws -> [SurpriseApp.Category] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        fetchCategoriesCalled = true
        return stubbedCategories
    }
}

// MARK: - MockGiftRepository

final class MockGiftRepository: GiftRepositoryProtocol {

    // MARK: - Stub data

    var stubbedGifts: [Gift] = []
    var stubbedCategories: [SurpriseApp.Category] = []
    var stubbedSearchResults: [Gift] = []
    var shouldThrow: Bool = false

    // MARK: - Call tracking

    private(set) var getAllGiftsCalled = false
    private(set) var getRecommendedGiftsCalled = false
    private(set) var getByCategoryCalledWithId: Int?
    private(set) var searchCalledWithQuery: String?

    // MARK: - GiftRepositoryProtocol

    func getAllGifts() async throws -> [Gift] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        getAllGiftsCalled = true
        return stubbedGifts
    }

    func getRecommendedGifts() async throws -> [Gift] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        getRecommendedGiftsCalled = true
        return stubbedGifts
    }

    func getByCategory(id: Int) async throws -> [Gift] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        getByCategoryCalledWithId = id
        return stubbedGifts.filter { $0.categories.contains(where: { $0.id == id }) }
    }

    func search(query: String) async throws -> [Gift] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        searchCalledWithQuery = query
        return stubbedSearchResults
    }

    func getCategories() async throws -> [SurpriseApp.Category] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        return stubbedCategories
    }
}

// MARK: - MockFavoritesService

final class MockFavoritesService: FavoritesServiceProtocol {

    var favoriteIds: Set<Int> = []
    var shouldThrow: Bool = false

    private(set) var toggleCalledWithId: Int?
    private(set) var syncCalled = false

    func toggleFavorite(id: Int) async throws {
        if shouldThrow { throw URLError(.cannotConnectToHost) }
        toggleCalledWithId = id
        if favoriteIds.contains(id) {
            favoriteIds.remove(id)
        } else {
            favoriteIds.insert(id)
        }
    }

    func isFavorite(id: Int) -> Bool {
        favoriteIds.contains(id)
    }

    func getFavoriteIds() -> Set<Int> {
        favoriteIds
    }

    func syncFromServer() async throws {
        syncCalled = true
    }

    func fetchFavoriteGifts() async throws -> [Gift] {
        return []
    }
}

// MARK: - MockAuthService

final class MockAuthService: AuthServiceProtocol {

    // MARK: - Stub data
    var stubbedUser = User(id: 1, name: "Test User", email: "test@test.com", phone: nil, isGuest: false)
    var stubbedToken = "test-token"
    var shouldThrow: Bool = false
    var stubError: Error = AuthError.invalidCredentials

    // MARK: - Call tracking
    private(set) var registerCalled = false
    private(set) var loginCalled = false
    private(set) var startGuestCalled = false
    private(set) var lastEmailOrPhone: String?
    private(set) var lastName: String?
    private(set) var lastPassword: String?

    // MARK: - AuthServiceProtocol

    func register(emailOrPhone: String, name: String, password: String) async throws -> AuthResponse {
        registerCalled = true
        lastEmailOrPhone = emailOrPhone
        lastName = name
        lastPassword = password
        if shouldThrow { throw stubError }
        return AuthResponse(user: stubbedUser, token: stubbedToken, refreshToken: nil)
    }

    func login(emailOrPhone: String, password: String) async throws -> AuthResponse {
        loginCalled = true
        lastEmailOrPhone = emailOrPhone
        lastPassword = password
        if shouldThrow { throw stubError }
        return AuthResponse(user: stubbedUser, token: stubbedToken, refreshToken: nil)
    }

    func startGuestSession() async -> User {
        startGuestCalled = true
        return User(id: 0, name: "Гость", email: nil, phone: nil, isGuest: true)
    }
}

// MARK: - MockPersonsService

final class MockPersonsService: PersonsServiceProtocol {

    var stubbedPersons: [Person] = []
    var stubbedPerson: Person = Person.make()
    var shouldThrow: Bool = false

    private(set) var fetchCalled = false
    private(set) var createCalled = false
    private(set) var updateCalledWithId: Int?
    private(set) var deleteCalledWithId: Int?

    func fetchPersons() async throws -> [Person] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        fetchCalled = true
        return stubbedPersons
    }

    func createPerson(
        name: String, eventDay: Int, eventMonth: Int,
        eventYear: Int?, eventType: PersonEventType, notes: String?
    ) async throws -> Person {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        createCalled = true
        return stubbedPerson
    }

    func updatePerson(
        id: Int, name: String?, eventDay: Int?, eventMonth: Int?,
        eventYear: Int?, eventType: PersonEventType?, notes: String?
    ) async throws -> Person {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        updateCalledWithId = id
        return stubbedPerson
    }

    func deletePerson(id: Int) async throws {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        deleteCalledWithId = id
    }
}

// MARK: - Person factory

extension Person {
    static func make(
        id: Int = 1,
        userId: Int = 1,
        name: String = "Test Person",
        eventDay: Int = 1,
        eventMonth: Int = 6,
        eventYear: Int? = nil,
        eventType: PersonEventType = .birthday,
        notes: String? = nil
    ) -> Person {
        Person(
            id: id,
            userId: userId,
            name: name,
            eventDay: eventDay,
            eventMonth: eventMonth,
            eventYear: eventYear,
            eventType: eventType,
            notes: notes,
            avatarUrl: nil,
            createdAt: nil
        )
    }
}

// MARK: - Gift factory

extension Gift {
    static func make(
        id: Int = 1,
        name: String = "Test Gift",
        price: Int = 1000,
        categories: [SurpriseApp.Category] = [],
        isFavorite: Bool = false,
        imageType: ImageType = .photo
    ) -> Gift {
        Gift(
            id: id,
            name: name,
            description: nil,
            price: price,
            imageURL: "",
            imageType: imageType,
            storeName: nil,
            storeURL: nil,
            createdAt: Date(),
            categories: categories,
            images: [],
            isFavorite: isFavorite
        )
    }
}
