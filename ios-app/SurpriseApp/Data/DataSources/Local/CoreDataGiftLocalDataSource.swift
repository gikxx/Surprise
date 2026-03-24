import Foundation
import CoreData

// MARK: - CoreDataGiftLocalDataSource
final class CoreDataGiftLocalDataSource: GiftLocalDataSourceProtocol {
    
    private let coreDataStack = CoreDataStack.shared
    
    // MARK: - Fetch All
    
    func fetchGifts() async throws -> [Gift] {
        print("📦 [CoreData] fetchGifts called")
        let context = coreDataStack.newBackgroundContext()
        
        return try await context.perform {
            let request: NSFetchRequest<GiftEntity> = GiftEntity.fetchRequest()
            let entities = try context.fetch(request)
            print("✅ [CoreData] fetched \(entities.count) entities")
            
            let gifts = entities.map { self.convertToGift(entity: $0) }
            print("🔄 [CoreData] converted to \(gifts.count) Gift models")
            return gifts
        }
    }
    
    // MARK: - Search
    
    func search(query: String) async throws -> [Gift] {
        let context = coreDataStack.newBackgroundContext()
        
        return try await context.perform {
            let request: NSFetchRequest<GiftEntity> = GiftEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "name CONTAINS[cd] %@ OR desc CONTAINS[cd] %@",
                query, query
            )
            
            let entities = try context.fetch(request)
            return entities.map { self.convertToGift(entity: $0) }
        }
    }
    
    // MARK: - Categories
    
    func fetchCategories() async throws -> [String] {
        let context = coreDataStack.newBackgroundContext()
        
        return try await context.perform {
            let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(key: "name", ascending: true)
            ]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.name }
        }
    }
    
    // MARK: - Mapping
    
    private func convertToGift(entity: GiftEntity) -> Gift {
        let categories = (entity.categories?.allObjects as? [GiftCategoryEntity])?
            .compactMap { $0.category?.name } ?? []
        
        return Gift(
            id: Int(entity.id),
            name: entity.name ?? "",
            description: entity.desc,
            price: Double(entity.price),
            imageURL: entity.imageURL ?? "",
            storeName: entity.storeName,
            storeURL: entity.storeURL,
            createdAt: entity.createdAt ?? Date(),
            categories: categories,
            isFavorite: false
        )
    }
}
