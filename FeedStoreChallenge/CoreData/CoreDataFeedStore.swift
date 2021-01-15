import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {

    private let context: NSManagedObjectContext

    public init(modelName: String, storeURL: URL, bundle: Bundle) throws {
        let container = try PersistentContainer(modelName: modelName, storeURL: storeURL, bundle: bundle)
        self.context = container.newBackgroundContext()
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {

        let context = self.context
        context.perform { [weak self] in

            guard let fetchedFeed = self?.fetchFeed() else {
                return completion(.empty)
            }

            let images = fetchedFeed.images?.array as? [PersistentFeedImage] ?? []
            let timestamp = fetchedFeed.timestamp ?? Date()

            completion(.found(feed: images.toLocalFeedImage(), timestamp: timestamp))
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

        let context = self.context
        context.perform { [weak self] in

            guard let fetchedFeed = self?.fetchFeed() else {
                return completion(nil)
            }
            self?.deleteFeed(fetchedFeed)
            completion(self?.save())
        }
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

        let context = self.context
        context.perform { [weak self] in

            if let fetchedFeed = self?.fetchFeed() {
                self?.deleteFeed(fetchedFeed)
            }

            let persistentFeed = PersistentFeed(context: context)
            let images = feed.toPersistentFeedImage(from: context)
            persistentFeed.addToImages(NSOrderedSet(array: images))
            persistentFeed.timestamp = timestamp
            completion(self?.save())
        }
    }

    // MARK: - Private Methods
    private func save() -> Error? {
        do {
            try context.save()
            return nil
        } catch {
            return error
        }
    }

    private func fetchFeed() -> PersistentFeed? {

        let request = NSFetchRequest<PersistentFeed>(entityName: "\(PersistentFeed.self)")
        return try? context.fetch(request).first
    }

    private func deleteFeed(_ feed: PersistentFeed) {
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

final class PersistentContainer: NSPersistentContainer {

    private struct CoreDataInitError: Error {}

    required init(modelName: String, storeURL: URL, bundle: Bundle) throws {

        guard let modelURL = bundle.url(forResource: modelName, withExtension: "momd") else {
            throw CoreDataInitError()
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoreDataInitError()
        }

        super.init(name: modelName, managedObjectModel: managedObjectModel)

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
