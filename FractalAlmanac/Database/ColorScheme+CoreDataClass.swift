//
//  ColorScheme+CoreDataClass.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//
import Foundation
import CoreData
import SwiftUI


@objc(ColorScheme)
class ColorScheme: NSManagedObject, ColorSchemeProtocol {

    func colorSchemeName() -> String {
        return self.name!
    }
    
    func colorSchemeColors() -> [UInt32] {
        return self.colors!
    }
    
    func colorSchemeFilter() -> RenderingFilter {
        return RenderingFilter(rawValue: (self.filter?.intValue)!) ?? .Off
    }
    
    static func newColorScheme() -> ColorScheme? {
        @Environment(\.managedObjectContext) var managedContext
        let entity = NSEntityDescription.entity(forEntityName: "ColorScheme", in: managedContext)!
       
        let colorScheme = NSManagedObject(entity: entity, insertInto: managedContext)
        return colorScheme as? ColorScheme
    }
    
    static func colorScheme(forName name:String) -> ColorScheme? {
        @Environment(\.managedObjectContext) var managedContext
        let fetchRequest =  NSFetchRequest<NSManagedObject>(entityName: "ColorScheme")
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K=%@", "name", name)

        var colorSchemes = [NSManagedObject]()
        do {
            colorSchemes = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return colorSchemes.first as? ColorScheme
    }
    
    static func allCustomColorSchemes() -> [ColorScheme]? {
        @Environment(\.managedObjectContext) var managedContext
        let fetchRequest =  NSFetchRequest<NSManagedObject>(entityName: "ColorScheme")
        var colorSchemes = [NSManagedObject]()
        do {
            colorSchemes = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return colorSchemes as? [ColorScheme]
    }
}

extension ColorScheme {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ColorScheme> {
        return NSFetchRequest<ColorScheme>(entityName: "ColorScheme")
    }

    @NSManaged public var colors: [UInt32]?
    @NSManaged public var filter: NSDecimalNumber?
    @NSManaged public var name: String?

}

extension ColorScheme : Identifiable {

}
