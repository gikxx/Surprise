import Foundation
import CoreData

// MARK: - CoreDataGiftLocalDataSource
final class CoreDataGiftLocalDataSource: GiftLocalDataSourceProtocol {

    private let coreDataStack = CoreDataStack.shared

    // MARK: - Fetch All

    func fetchGifts() async throws -> [Gift] {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            let request: NSFetchRequest<GiftEntity> = GiftEntity.fetchRequest()
            let entities = try context.fetch(request)

            let gifts = entities.map { self.convertToGift(entity: $0) }
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

    func fetchCategories() async throws -> [Category] {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(key: "name", ascending: true)
            ]

            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let name = entity.name else { return nil }
                return Category(id: Int(entity.id), name: name)
            }
        }
    }

    // MARK: - Mapping

    private func convertToGift(entity: GiftEntity) -> Gift {
        let categories: [Category] = (entity.categories?.allObjects as? [GiftCategoryEntity])?
            .compactMap { joinEntity -> Category? in
                guard
                    let categoryEntity = joinEntity.category,
                    let name = categoryEntity.name
                else {
                    return nil
                }
                return Category(id: Int(categoryEntity.id), name: name)
            } ?? []

        let imageURL = entity.imageURL ?? ""
        let coverImage = GiftImage(url: imageURL, sortOrder: 0, isPrimary: true)

        return Gift(
            id: Int(entity.id),
            name: entity.name ?? "",
            description: entity.desc,
            price: Int(entity.price),
            imageURL: imageURL,
            storeName: entity.storeName,
            storeURL: entity.storeURL,
            createdAt: entity.createdAt ?? Date(),
            categories: categories,
            images: [coverImage],
            isFavorite: false
        )
    }
}
