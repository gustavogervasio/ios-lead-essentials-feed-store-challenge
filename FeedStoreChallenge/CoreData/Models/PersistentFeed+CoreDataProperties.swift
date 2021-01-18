import Foundation
import CoreData

extension PersistentFeed {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersistentFeed> {
        return NSFetchRequest<PersistentFeed>(entityName: "PersistentFeed")
    }

    @NSManaged public var timestamp: Date
    @NSManaged public var images: NSOrderedSet

}

// MARK: Generated accessors for images
extension PersistentFeed {

    @objc(insertObject:inImagesAtIndex:)
    @NSManaged public func insertIntoImages(_ value: PersistentFeedImage, at idx: Int)

    @objc(removeObjectFromImagesAtIndex:)
    @NSManaged public func removeFromImages(at idx: Int)

    @objc(insertImages:atIndexes:)
    @NSManaged public func insertIntoImages(_ values: [PersistentFeedImage], at indexes: NSIndexSet)

    @objc(removeImagesAtIndexes:)
    @NSManaged public func removeFromImages(at indexes: NSIndexSet)

    @objc(replaceObjectInImagesAtIndex:withObject:)
    @NSManaged public func replaceImages(at idx: Int, with value: PersistentFeedImage)

    @objc(replaceImagesAtIndexes:withImages:)
    @NSManaged public func replaceImages(at indexes: NSIndexSet, with values: [PersistentFeedImage])

    @objc(addImagesObject:)
    @NSManaged public func addToImages(_ value: PersistentFeedImage)

    @objc(removeImagesObject:)
    @NSManaged public func removeFromImages(_ value: PersistentFeedImage)

    @objc(addImages:)
    @NSManaged public func addToImages(_ values: NSOrderedSet)

    @objc(removeImages:)
    @NSManaged public func removeFromImages(_ values: NSOrderedSet)

}

extension PersistentFeed : Identifiable {

}
