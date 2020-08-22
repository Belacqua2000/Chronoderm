//
//  ContentView.swift
//  Shared
//
//  Created by Nick Baughan on 22/08/2020.
//

import SwiftUI
import CoreData

struct ContentView: View {

    var body: some View {
        SidebarNavigation()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
