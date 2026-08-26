//
//  ColorScheme+CoreDataClass.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 6/29/26.
//
import Foundation
internal import CoreData
import OSLog
import SwiftUI


@objc(ColorScheme)
class ColorScheme: NSManagedObject {
    
    static func newColorScheme(on managedContext: NSManagedObjectContext) -> ColorScheme? {
        let entity = NSEntityDescription.entity(forEntityName: "ColorScheme", in: managedContext)!
       
        let colorScheme = NSManagedObject(entity: entity, insertInto: managedContext)
        return colorScheme as? ColorScheme
    }
    
    static func colorScheme(forName name:String, on managedContext: NSManagedObjectContext) -> ColorScheme? {
        let fetchRequest =  NSFetchRequest<NSManagedObject>(entityName: "ColorScheme")
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K=%@", "name", name)

        var colorSchemes = [NSManagedObject]()
        do {
            colorSchemes = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            Logger.compute.error("Could not fetch. \(error.localizedDescription, privacy: .public) \(String(describing: error.userInfo), privacy: .public)")
        }
        return colorSchemes.first as? ColorScheme
    }
    
    static func allCustomColorSchemes(on managedContext: NSManagedObjectContext) -> [ColorScheme]? {
        var colorSchemes = [NSManagedObject]()
        do {
            colorSchemes = try managedContext.fetch(fetchRequest())
        } catch let error as NSError {
            Logger.compute.error("Could not fetch. \(error.localizedDescription, privacy: .public) \(String(describing: error.userInfo), privacy: .public)")
        }
        return colorSchemes as? [ColorScheme]
    }
}

extension ColorScheme {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ColorScheme> {
        return NSFetchRequest<ColorScheme>(entityName: "ColorScheme")
    }

    @NSManaged public var colors: Data?
    @NSManaged public var filter: NSDecimalNumber?
    @NSManaged public var name: String?

}

extension ColorScheme : ColorSchemeProtocol {
    var stableID: String { self.objectID.uriRepresentation().absoluteString}
    
    var paletteName: String {
        return self.name!
    }
    
    var paletteShaderColors: [Float] {
        return self.colorsArray.map(\.shaderColor).flatMap{ $0 }
    }
    
    func schemeColors() -> [UInt32] {
        return self.colorsArray
    }
    
    func schemeSystemColors() -> [Color] {
        return self.colorsArray.map { color in
            color.systemColor
        }
    }
    
    func colorSchemeFilter() -> RenderingFilter {
        return RenderingFilter(rawValue: (self.filter?.intValue)!) ?? .Off
    }
}
