import CoreData
import UIKit

struct JSONGift: Codable {
    let id: Int
    let name: String
    let description: String
    let price: Int
    let imageURL: String
    let storeName: String
    let storeURL: String
    let createdAt: String
    let categoryIds: [Int]
}

struct JSONCategory: Codable {
    let id: Int
    let name: String
}

struct JSONData: Codable {
    let gifts: [JSONGift]
    let categories: [JSONCategory]
}

final class GiftDataLoader {
    static let shared = GiftDataLoader()
    private let coreDataStack = CoreDataStack.shared
    
    private init() {}
    
    func loadInitialGiftsIfNeeded() {
        let context = coreDataStack.newBackgroundContext()
        
        context.perform {
            let request: NSFetchRequest<GiftEntity> = GiftEntity.fetchRequest()
            request.fetchLimit = 1
            
            do {
                let count = try context.count(for: request)
                if count == 0 {
                    self.loadGiftsFromJSON(into: context)
                }
            } catch {
                #if DEBUG
                print("Failed to check gifts existence: \(error)")
                #endif
            }
        }
    }
    
    private func loadGiftsFromJSON(into context: NSManagedObjectContext) {
        guard let url = Bundle.main.url(forResource: "gifts", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            #if DEBUG
            print("❌ Failed to load gifts.json")
            #endif
            return
        }
        
        do {
            let jsonData = try JSONDecoder().decode(JSONData.self, from: data)
            
            var categoryMap = [Int: CategoryEntity]()
            for jsonCategory in jsonData.categories {
                let category = CategoryEntity(context: context)
                category.id = Int64(jsonCategory.id)
                category.name = jsonCategory.name
                categoryMap[jsonCategory.id] = category
            }
            
            for jsonGift in jsonData.gifts {
                let gift = GiftEntity(context: context)
                gift.id = Int64(jsonGift.id)
                gift.name = jsonGift.name
                gift.desc = jsonGift.description
                gift.price = Int64(jsonGift.price)
                gift.imageURL = jsonGift.imageURL
                gift.storeName = jsonGift.storeName
                gift.storeURL = jsonGift.storeURL
                
                let formatter = ISO8601DateFormatter()
                gift.createdAt = formatter.date(from: jsonGift.createdAt)
                
                for categoryId in jsonGift.categoryIds {
                    if let category = categoryMap[categoryId] {
                        let giftCategory = GiftCategoryEntity(context: context)
                        giftCategory.id = Int64("\(jsonGift.id)\(categoryId)") ?? 0
                        giftCategory.createdAt = Date()
                        giftCategory.gift = gift
                        giftCategory.category = category
                    }
                }
            }
            
            try context.save()
            
        } catch {
            #if DEBUG
            print("❌ Failed to parse or save gifts: \(error)")
            #endif
        }
    }
}
