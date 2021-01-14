import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {

    private struct CoreDataError: Error {}

    private lazy var container: NSPersistentContainer = {
        let modelName = "FeedStore"
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: modelName, withExtension: "momd") else {
            fatalError("ModelURL is unavailable")
        }
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Model is unavailable")
        }

        let container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error), \(error)")
            }
        })
        return container
    }()

    public init() {}

    public func retrieve(completion: @escaping RetrievalCompletion) {

        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "PersistentFeed")
        guard let fetchedFeed = try? context.fetch(request) else {
            return completion(.failure(CoreDataError()))
        }
        guard let feed = fetchedFeed.last else { return completion(.empty) }

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

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {}

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

        let context = container.viewContext
        guard let feedImageEntity = NSEntityDescription.entity(forEntityName: "PersistentFeedImage", in: context) else {
            return completion(CoreDataError())
        }

        guard let feedEntity = NSEntityDescription.entity(forEntityName: "PersistentFeed", in: context) else {
            return completion(CoreDataError())
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
        completion(nil)
    }
}
