import Foundation

// MARK: - FeedViewModelProtocol
protocol FeedViewModelProtocol: AnyObject {
    var title: String { get }
    var gifts: [Gift] { get }
    func loadGifts()
}

// MARK: - FeedViewModel
final class FeedViewModel: FeedViewModelProtocol {
    
    // MARK: - Properties
    let title = "Идеи подарков"
    private(set) var gifts: [Gift] = []
    
    // MARK: - Public Methods
    func loadGifts() {
        // позже здесь будет запрос к FastAPI
        gifts = [
            Gift(name: "Набор свечей", price: 1500, category: "Дом", imageName: "candles"),
            Gift(name: "Умная колонка", price: 7000, category: "Техника", imageName: "speaker"),
            Gift(name: "Плед", price: 2500, category: "Уют", imageName: "blanket"),
            Gift(name: "Книга рецептов", price: 1200, category: "Кухня", imageName: "book")
        ]
    }
}
