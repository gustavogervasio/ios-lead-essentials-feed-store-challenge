import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {

    private let context: NSManagedObjectContext

    public init(storeURL: URL) throws {
        let container = try PersistentContainer(storeURL: storeURL)
        self.context = container.newBackgroundContext()
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {

        let context = self.context
        context.perform { [weak self] in

            do {
                guard let fetchedFeed = try self?.fetchFeed(), let images = fetchedFeed.images.array as? [PersistentFeedImage] else {
                    return completion(.empty)
                }

                let timestamp = fetchedFeed.timestamp

                completion(.found(feed: images.toLocalFeedImage(), timestamp: timestamp))

            } catch {

                completion(.failure(error))
            }
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

        let context = self.context
        context.perform { [weak self] in

            do {

                guard let fetchedFeed = try self?.fetchFeed() else {
                    return completion(nil)
                }
                self?.deleteFeed(fetchedFeed)

                completion(context.saveIfNeeded())

            } catch {
                completion(error)
            }
        }
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

        let context = self.context
        context.perform { [weak self] in

            do {

                if let fetchedFeed = try self?.fetchFeed() {
                    self?.deleteFeed(fetchedFeed)
                }

                let persistentFeed = PersistentFeed(context: context)
                let images = feed.toPersistentFeedImage(from: context)
                persistentFeed.addToImages(NSOrderedSet(array: images))
                persistentFeed.timestamp = timestamp

                completion(context.saveIfNeeded())

            } catch {
                completion(error)
            }
        }
    }

    // MARK: - Private Methods
    private func fetchFeed() throws -> PersistentFeed? {

        let request = NSFetchRequest<PersistentFeed>(entityName: "\(PersistentFeed.self)")
        return try context.fetch(request).first
    }

    private func deleteFeed(_ feed: PersistentFeed) {
        context.delete(feed)
    }

}

private extension Array where Element == PersistentFeedImage {

    func toLocalFeedImage() -> [LocalFeedImage] {

        return compactMap { persistentImage -> LocalFeedImage in

            let id = persistentImage.id
            let description = persistentImage.desc
            let location = persistentImage.location
            let url = persistentImage.url

            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
}

private extension Array where Element == LocalFeedImage {

    func toPersistentFeedImage(from context: NSManagedObjectContext) -> [PersistentFeedImage] {

        return compactMap { feedImage -> PersistentFeedImage in

            let persistentFeedImage = PersistentFeedImage(context: context)
            persistentFeedImage.id = feedImage.id
            persistentFeedImage.desc = feedImage.description
            persistentFeedImage.location = feedImage.location
            persistentFeedImage.url = feedImage.url
            return persistentFeedImage
        }
    }
}

extension NSManagedObjectContext {

    func saveIfNeeded() -> Error? {
        if hasChanges {
            do {
                try save()
            } catch {
                return error
            }
        }
        return nil
    }
}
