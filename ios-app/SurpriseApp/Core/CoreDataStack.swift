import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    
    private init() {}
    
    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Surprise")
        
        let description = NSPersistentStoreDescription()
        description.url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Surprise.sqlite")
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        return container
    }()
    
    // MARK: - Contexts
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Save
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}
