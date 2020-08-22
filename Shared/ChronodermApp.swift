//
//  ChronodermApp.swift
//  Shared
//
//  Created by Nick Baughan on 22/08/2020.
//

import SwiftUI

@main
struct ChronodermApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
