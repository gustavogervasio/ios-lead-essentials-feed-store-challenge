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
        context.perform {

            do {
                guard let fetchedFeed = try PersistentFeed.first(in: context),
                      let images = fetchedFeed.images.array as? [PersistentFeedImage] else {

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
        context.perform {

            do {

                guard let fetchedFeed = try PersistentFeed.first(in: context) else {
                    return completion(nil)
                }
                context.delete(fetchedFeed)
                completion(context.saveIfNeeded())

            } catch {
                completion(error)
            }
        }
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

        let context = self.context
        context.perform {

            do {

                if let fetchedFeed = try PersistentFeed.first(in: context) {
                    context.delete(fetchedFeed)
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

private extension PersistentFeed {

    static func first(in context: NSManagedObjectContext) throws -> PersistentFeed? {

        let request: NSFetchRequest<PersistentFeed> = PersistentFeed.fetchRequest()
        return try context.fetch(request).first
    }
}
