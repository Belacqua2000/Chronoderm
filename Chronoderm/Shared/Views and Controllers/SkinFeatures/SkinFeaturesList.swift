//
//  SkinFeaturesList.swift
//  Chronoderm
//
//  Created by Nick Baughan on 23/08/2020.
//

import SwiftUI

@available(iOS 14.0, *)
struct SkinFeaturesList: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(entity: SkinFeature.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \SkinFeature.startDate, ascending: true)]) var skinFeatures: FetchedResults<SkinFeature>
    @State var isNewFeatureShown: Bool = false
    @State var isSettingsShown: Bool = false
    var body: some View {
        List {
            Section(header: Text("All Features")) {
                ForEach(skinFeatures, id: \.self) { feature in
                    //SkinFeaturesCellView(feature: feature)
                    NavigationLink(destination: EntriesView(feature: feature)) {
                        Label(feature.name!, systemImage: "photo")
                    }
                    /*.contextMenu {
                            Button("Menu Item 1", action: {})
                            Button("Menu Item 2", action: {})
                            Button("Menu Item 2", action: {})
                    }*/

                }
            }
                Button {
                    self.isNewFeatureShown = true
                } label: {
                    Label("Add Feature", systemImage: "plus")
                }
                .sheet(isPresented: $isNewFeatureShown, content: {
                    AddFeatureView(date: Date(), featureName: "", featureArea: "", isViewShown: $isNewFeatureShown)
                })
            
        }
        //.listStyle(SidebarListStyle())
        .navigationTitle("Skin Features")
        .sheet(isPresented: $isSettingsShown) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isSettingsShown = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }
}

@available(iOS 14.0, *)
struct SkinFeaturesList_Previews: PreviewProvider {
    static var previews: some View {
        SkinFeaturesList()
    }
}
