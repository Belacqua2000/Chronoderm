//
//  SidebarNavigation.swift
//  Chronoderm
//
//  Created by Nick Baughan on 20/08/2020.
//

import SwiftUI

@available(iOS 14.0, *)
struct SidebarNavigation: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(entity: SkinFeature.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \SkinFeature.startDate, ascending: true)]) var skinFeatures: FetchedResults<SkinFeature>
    var body: some View {
        NavigationView {
            List(skinFeatures, id: \.self) { feature in
                SkinFeaturesCellView(feature: feature)
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Skin Features")
            EntriesView()
        }
    }
}

@available(iOS 14.0, *)
struct SidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        Group {
            SidebarNavigation().environment(\.managedObjectContext, context)
            SidebarNavigation().environment(\.managedObjectContext, context)
        }
    }
}
