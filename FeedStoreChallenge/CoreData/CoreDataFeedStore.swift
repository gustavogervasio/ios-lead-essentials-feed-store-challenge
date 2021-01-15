import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {

    private struct CoreDataError: Error {}

    private let container: NSPersistentContainer

    public init(container: NSPersistentContainer) {
        self.container = container
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {

        let context = container.viewContext
        context.perform { [weak self] in
            guard let fetchedFeed = self?.fetchFeed(from: context) else {
                return completion(.empty)
            }

            let images = fetchedFeed.mutableOrderedSetValue(forKeyPath: "images").array as! [NSManagedObject]
            let timestamp = fetchedFeed.value(forKey: "timestamp") as! Date

            let localFeed = images.map { image -> LocalFeedImage in

                let id = image.value(forKey: "id") as! UUID
                let description = image.value(forKey: "desc") as? String
                let location = image.value(forKey: "location") as? String
                let url = image.value(forKey: "url") as! URL

                return LocalFeedImage(id: id, description: description, location: location, url: url)
            }

            completion(.found(feed: localFeed, timestamp: timestamp))
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

        let context = container.viewContext
        context.perform { [weak self] in
            if let fetchedFeed = self?.fetchFeed(from: context) {
                self?.deleteFeed(fetchedFeed, fromContext: context)
                completion(self?.save(context: context))
            } else {
                completion(nil)
            }
        }
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

        let context = container.viewContext
        context.perform { [weak self] in
            guard let feedImageEntity = NSEntityDescription.entity(forEntityName: "PersistentFeedImage", in: context) else {
                return completion(CoreDataError())
            }

            guard let feedEntity = NSEntityDescription.entity(forEntityName: "PersistentFeed", in: context) else {
                return completion(CoreDataError())
            }

            if let fetchedFeed = self?.fetchFeed(from: context) {
                self?.deleteFeed(fetchedFeed, fromContext: context)
            }

            let images = feed.map { localFeedImage -> NSManagedObject in
                let persistentFeedImage = NSManagedObject(entity: feedImageEntity, insertInto: context)
                persistentFeedImage.setValue(localFeedImage.description, forKey: "desc")
                persistentFeedImage.setValue(localFeedImage.id, forKey: "id")
                persistentFeedImage.setValue(localFeedImage.location, forKey: "location")
                persistentFeedImage.setValue(localFeedImage.url, forKey: "url")

                return persistentFeedImage
            }

            let persistentFeed = NSManagedObject(entity: feedEntity, insertInto: context)
            persistentFeed.mutableOrderedSetValue(forKeyPath: "images").addObjects(from: images)
            persistentFeed.setValue(timestamp, forKey: "timestamp")

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

    private func fetchFeed(from context: NSManagedObjectContext) -> NSManagedObject? {

        let request = NSFetchRequest<NSManagedObject>(entityName: "PersistentFeed")
        return try? context.fetch(request).first
    }

    private func deleteFeed(_ feed: NSManagedObject, fromContext context: NSManagedObjectContext) {
        context.delete(feed)
    }
}
