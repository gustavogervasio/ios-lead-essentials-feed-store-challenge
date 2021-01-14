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
        let request = NSFetchRequest<NSManagedObject>(entityName: "PersistentFeed")
        guard let fetchedFeed = try? context.fetch(request) else {
            return completion(.failure(CoreDataError()))
        }
        guard let feed = fetchedFeed.first else { return completion(.empty) }

        let images = feed.mutableOrderedSetValue(forKeyPath: "images").array as! [NSManagedObject]
        let timestamp = feed.value(forKey: "timestamp") as! Date

        let localFeed = images.map { image -> LocalFeedImage in

            let id = image.value(forKey: "id") as! UUID
            let description = image.value(forKey: "desc") as? String
            let location = image.value(forKey: "location") as? String
            let url = image.value(forKey: "url") as! URL

            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }

        completion(.found(feed: localFeed, timestamp: timestamp))
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        completion(nil)
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

        let context = container.viewContext
        guard let feedImageEntity = NSEntityDescription.entity(forEntityName: "PersistentFeedImage", in: context) else {
            return completion(CoreDataError())
        }

        guard let feedEntity = NSEntityDescription.entity(forEntityName: "PersistentFeed", in: context) else {
            return completion(CoreDataError())
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "PersistentFeed")
        if let fetchedFeed = try? context.fetch(request) {
            let _ = fetchedFeed.map({context.delete($0)})
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

        do {
            try context.save()
            completion(nil)
        } catch {
            completion(error)
        }
    }
}
