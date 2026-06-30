//
//  FractalAlmanacApp.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import SwiftUI
import CoreData

@main
struct FractalAlmanacApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
