//
//  Bookmark+CoreDataClass.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//
internal import CoreData
import UIKit


class Bookmark: NSManagedObject, SnapshotObject {
    class func newBookmark(in managedContext: NSManagedObjectContext) -> Bookmark? {
        let entity = NSEntityDescription.entity(forEntityName: "Bookmark", in: managedContext)!
        let bookmark = NSManagedObject(entity: entity, insertInto: managedContext)
        return bookmark as? Bookmark
    }
    
    class func bookmark(forName name:String, in managedContext: NSManagedObjectContext) -> Bookmark? {
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
    
    class func allBookmarks(in managedContext: NSManagedObjectContext) -> [Bookmark]? {
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

    class func delete(_ bookmark:Bookmark, in managedContext: NSManagedObjectContext) -> Bool {
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
        return name
    }
    
    func modelName() -> String {
        return model
    }
    
    func center() -> (centerReal: Double, centerImag: Double) {
        return (centerReal, centerImag)
    }
    
    func zoom() -> Double {
        return zoomFactor
    }
    
    func colorScheme() -> any ColorSchemeProtocol {
        if let p = Palette(rawValue: palette) {
            return p
        } else if let c = ColorScheme.colorScheme(
            forName: palette,
            on:PersistenceController.shared.container.viewContext
        ) {
            return c
        } else {
            return Palette.Vibrant
        }
    }
    
    func image() -> UIImage {
        return UIImage(data: thumbnail) ?? UIImage()
    }
}

extension Bookmark {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bookmark> {
        return NSFetchRequest<Bookmark>(entityName: "Bookmark")
    }

    @NSManaged public var name: String
    @NSManaged public var centerReal: Double
    @NSManaged public var centerImag: Double
    @NSManaged public var zoomFactor: Double
    @NSManaged public var model: String
    @NSManaged public var palette: String
    @NSManaged public var thumbnail: Data
    @NSManaged public var timestamp: Date

}

extension Bookmark : Identifiable {

}
