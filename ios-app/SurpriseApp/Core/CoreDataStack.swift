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
        // Открываем store синхронно — на холодном старте всё равно дождёмся,
        // но без этого флага некоторые версии Core Data грузят асинхронно и
        // блокируют первый запрос viewContext'а из main.
        description.shouldAddStoreAsynchronously = false

        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }

        // Импорт `gifts.json` идёт в фоновом контексте.
        // Без этого флага его save() не виден из viewContext без ручного merge,
        // и Feed на первом запуске показывает пусто, пока не перезагрузишь.
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

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
                #if DEBUG
                print("Failed to save context: \(error)")
                #endif
            }
        }
    }
}
