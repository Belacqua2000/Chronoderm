//
//  SidebarNavigation.swift
//  Chronoderm
//
//  Created by Nick Baughan on 20/08/2020.
//

import SwiftUI

@available(iOS 14.0, *)
struct SidebarNavigation: View {
    var body: some View {
        NavigationView {
            SkinFeaturesList()
            Text("Select or create a skin feature from the sidebar on the left")
        }
    }
}

@available(iOS 14.0, *)
struct SidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            SidebarNavigation().environment(\.managedObjectContext, context)
    }
}
