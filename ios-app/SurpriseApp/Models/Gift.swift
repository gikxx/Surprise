import Foundation

// MARK: - Gift Model
struct Gift: Identifiable {
    let id = UUID()
    let name: String
    let price: Int
    let category: String
    let imageName: String
    var isFavorite: Bool = false
}
