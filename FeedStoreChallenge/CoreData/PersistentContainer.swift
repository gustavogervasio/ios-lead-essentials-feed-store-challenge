import Foundation
import CoreData

final class PersistentContainer: NSPersistentContainer {

    private struct ModelNotFound: Error {}

    static private let modelName = "FeedStore"
    static private let bundle = Bundle(for: PersistentContainer.self)

    required init(storeURL: URL) throws {

        guard let modelURL = PersistentContainer.bundle.url(forResource: PersistentContainer.modelName, withExtension: "momd") else {
            throw ModelNotFound()
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            throw ModelNotFound()
        }

        super.init(name: PersistentContainer.modelName, managedObjectModel: managedObjectModel)

        try loadStoresFromURL(storeURL)
    }

    // MARK: - Private Methods
    private func loadStoresFromURL(_ url: URL) throws {

        let description = NSPersistentStoreDescription()
        description.url = url
        persistentStoreDescriptions = [description]

        var loadError: Error?
        loadPersistentStores(completionHandler: { (storeDescription, error) in
            loadError = error
        })
        guard let error = loadError else { return }
        throw error
    }
}
