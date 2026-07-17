//
//  FractalAlmanacApp.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import SwiftUI
internal import CoreData

@main
struct FractalAlmanacApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                InfoDisplay()
            }
        }
    }
}
