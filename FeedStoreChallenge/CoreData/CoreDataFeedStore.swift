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

            let images = fetchedFeed.images?.array as? [PersistentFeedImage] ?? []
            let timestamp = fetchedFeed.timestamp ?? Date()

            let localFeed = images.map { image -> LocalFeedImage in

                let id = image.id ?? UUID()
                let description = image.desc ?? ""
                let location = image.location ?? ""
                let url = image.url ?? URL(string: "")!

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

            if let fetchedFeed = self?.fetchFeed(from: context) {
                self?.deleteFeed(fetchedFeed, fromContext: context)
            }

            let images = feed.map { localFeedImage -> PersistentFeedImage in
                let persistentFeedImage = PersistentFeedImage(context: context)
                persistentFeedImage.id = localFeedImage.id
                persistentFeedImage.desc = localFeedImage.description
                persistentFeedImage.location = localFeedImage.location
                persistentFeedImage.url = localFeedImage.url
                return persistentFeedImage
            }
            let persistentFeed = PersistentFeed(context: context)
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

        let request = NSFetchRequest<PersistentFeed>(entityName: "PersistentFeed")
        return try? context.fetch(request).first
    }

    private func deleteFeed(_ feed: NSManagedObject, fromContext context: NSManagedObjectContext) {
        context.delete(feed)
    }
}
