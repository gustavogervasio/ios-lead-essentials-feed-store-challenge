import Foundation
import CoreData

extension PersistentFeedImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersistentFeedImage> {
        return NSFetchRequest<PersistentFeedImage>(entityName: "PersistentFeedImage")
    }

    @NSManaged public var desc: String?
    @NSManaged public var id: UUID?
    @NSManaged public var location: String?
    @NSManaged public var url: URL?
    @NSManaged public var feed: PersistentFeed?

}

extension PersistentFeedImage : Identifiable {}
