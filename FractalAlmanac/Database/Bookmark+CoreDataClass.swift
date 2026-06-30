//
//  Bookmark+CoreDataClass.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//
import CoreData
import UIKit


class Bookmark: NSManagedObject, SnapshotObject {
    class func newBookmark() -> Bookmark? {
        let managedContext = PersistenceController.shared.container.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Bookmark", in: managedContext)!
        let bookmark = NSManagedObject(entity: entity, insertInto: managedContext)
        return bookmark as? Bookmark
    }
    
    class func bookmark(forName name:String) -> Bookmark? {
        let managedContext = PersistenceController.shared.container.viewContext
        let fetchRequest:NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K=%@", "name", name)
        
        var bookmarks = [NSManagedObject]()
        do {
            bookmarks = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return bookmarks.first as? Bookmark
    }
    
    class func allBookmarks() -> [Bookmark]? {
        let managedContext = PersistenceController.shared.container.viewContext
        let fetchRequest:NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        var bookmarks = [NSManagedObject]()
        do {
            bookmarks = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return bookmarks as? [Bookmark]
    }

    class func delete(_ bookmark:Bookmark) -> Bool {
        let managedContext = PersistenceController.shared.container.viewContext
        managedContext.delete(bookmark)
        do {
            try managedContext.save()
            return true
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
            return false
        }
    }
    
    func snapshotName() -> String {
        return name ?? ""
    }
    
    func modelName() -> String {
        return model ?? ""
    }
    
    func colorScheme() -> ColorSchemeProtocol {
        if let p = Palette(rawValue: palette!) {
            return p
        } else if let c = ColorScheme.colorScheme(forName: palette!) {
            return c
        } else {
            return Palette.Vibrant
        }
    }
    
    func drawingExtents() -> Extent {
        if let extents {
            return extents.toExtent()
        }
        return CGRectZero.toExtent()
    }
    
    func image() -> UIImage {
        return UIImage(data: thumbnail ?? Data()) ?? UIImage()
    }
}

extension Bookmark {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bookmark> {
        return NSFetchRequest<Bookmark>(entityName: "Bookmark")
    }

    @NSManaged public var name: String?
    @NSManaged public var extents: [Double]?
    @NSManaged public var model: String?
    @NSManaged public var palette: String?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var timestamp: Date?

}

extension Bookmark : Identifiable {

}
