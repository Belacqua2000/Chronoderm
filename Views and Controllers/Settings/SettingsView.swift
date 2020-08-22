//
//  SettingsView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 21/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct SettingsView: View {
    var vc: UIViewController?
    var body: some View {
        NavigationView {
                SettingsContentView()
                    .navigationTitle("Settings")
                    .navigationBarItems(trailing: Button("Done", action: dismiss))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    func dismiss() {
        vc?.dismiss(animated: true, completion: nil)
    }
}

@available(iOS 14.0, *)
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

@available(iOS 14.0, *)
struct SettingsContentView: View {
    @State var isTutorialPresented: Bool = false
    //var settings: [String: Any]
    @AppStorage("saveImageToPhotos") var saveImageToPhotos: Bool = false
    @AppStorage("indexSpotlight") var indexSpotlight: Bool = false
    @AppStorage("showHomeQuickActions") var showHomeQuickActions: Bool = false
    var body: some View {
        Form {
            Section {
                NavigationLink(destination: HelpView()){
                    Label("Help", systemImage: "questionmark")
                }
                Button(action: {isTutorialPresented = true}, label: {
                    Label("Tutorial", systemImage: "book")
                        .foregroundColor(Color.primary)
                })
                   
            }
            Section(header: Text("Camera Preferences")) {
                Toggle(isOn: $saveImageToPhotos) {
                    Label("Save Captured Images to Photos", systemImage: "photo.on.rectangle")
                }
                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    Label("Set Camera Permissions", systemImage: "hand.raised")
                }
            }
            Section(header: Text("Privacy")) {
                Toggle(isOn: $showHomeQuickActions) {
                    Label("Show Quick Actions", systemImage: "rectangle.grid.1x2")
                }
                Toggle(isOn: $indexSpotlight) {
                    Label("Show In Spotlight", systemImage: "magnifyingglass")
                }
            }
            Section(header: Text("About")) {
                HStack {
                    Text("Version Number")
                    Spacer()
                    Text(GlobalVariables().currentVersion!)
                }
                HStack {
                    Text("Build Number")
                    Spacer()
                    Text(GlobalVariables().currentBuild!)
                }
            }
            .foregroundColor(.secondary)
        }
        .fullScreenCover(isPresented: $isTutorialPresented, content: {
            OnboardingView(swiftUI: true)
        })
        .listStyle(GroupedListStyle())
    }
}
