import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {

    private struct CoreDataError: Error {}

    private let container: NSPersistentContainer

    public init(storeURL: URL? = nil) {

        let container: NSPersistentContainer = {
            let modelName = "FeedStore"
            guard let modelURL = Bundle(for: CoreDataFeedStore.self).url(forResource: modelName, withExtension: "momd") else {
                fatalError("ModelURL is unavailable")
            }
            guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
                fatalError("Model is unavailable")
            }

            let container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)

            let description = NSPersistentStoreDescription()
            description.url = storeURL
            container.persistentStoreDescriptions = [description]

            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error {
                    fatalError("Unresolved error \(error), \(error)")
                }
            })
            return container
        }()

        self.container = container
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {

        let context = container.viewContext
        context.perform { [weak self] in

            guard let fetchedFeed = self?.fetchFeed(from: context) else {
                return completion(.empty)
            }

            let images = fetchedFeed.images?.array as? [PersistentFeedImage] ?? []
            let timestamp = fetchedFeed.timestamp ?? Date()

            completion(.found(feed: images.toLocalFeedImage(), timestamp: timestamp))
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

        let context = container.viewContext
        context.perform { [weak self] in

            guard let fetchedFeed = self?.fetchFeed(from: context) else {
                return completion(nil)
            }
            self?.deleteFeed(fetchedFeed, fromContext: context)
            completion(self?.save(context: context))
        }
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

        let context = container.viewContext
        context.perform { [weak self] in

            if let fetchedFeed = self?.fetchFeed(from: context) {
                self?.deleteFeed(fetchedFeed, fromContext: context)
            }

            let persistentFeed = PersistentFeed(context: context)
            let images = feed.toPersistentFeedImage(from: context)
            persistentFeed.addToImages(NSOrderedSet(array: images))
            persistentFeed.timestamp = timestamp
            completion(self?.save(context: context))
        }
    }

    // MARK: - Private Methods
    private func save(context: NSManagedObjectContext) -> Error? {
        do {
            try context.save()
            return nil
        } catch {
            return error
        }
    }

    private func fetchFeed(from context: NSManagedObjectContext) -> PersistentFeed? {

        let request = NSFetchRequest<PersistentFeed>(entityName: "\(PersistentFeed.self)")
        return try? context.fetch(request).first
    }

    private func deleteFeed(_ feed: PersistentFeed, fromContext context: NSManagedObjectContext) {
        context.delete(feed)
    }
}


private extension Array where Element == PersistentFeedImage {

    func toLocalFeedImage() -> [LocalFeedImage] {

        return map { persistentImage -> LocalFeedImage in

            let id = persistentImage.id ?? UUID()
            let description = persistentImage.desc ?? ""
            let location = persistentImage.location ?? ""
            let url = persistentImage.url ?? URL(string: "")!

            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
}

private extension Array where Element == LocalFeedImage {

    func toPersistentFeedImage(from context: NSManagedObjectContext) -> [PersistentFeedImage] {

        return map { feedImage -> PersistentFeedImage in

            let persistentFeedImage = PersistentFeedImage(context: context)
            persistentFeedImage.id = feedImage.id
            persistentFeedImage.desc = feedImage.description
            persistentFeedImage.location = feedImage.location
            persistentFeedImage.url = feedImage.url
            return persistentFeedImage
        }
    }
}
