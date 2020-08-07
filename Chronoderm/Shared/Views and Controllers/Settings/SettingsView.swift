//
//  SettingsView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 21/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
                SettingsContentView()
                    .navigationBarTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

struct SettingsContentView: View {
    //var settings: [String: Any]
    @ObservedObject var settings = userDefault()
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "questionmark")
                    Text("Help")
                }
                CompatibleLabel(symbolName: "book", text: "Tutorial")
            }
            Section(header: Text("Camera Preferences")) {
                HStack {
                    Image(systemName: "camera")
                    Toggle("Show Camera Overlay", isOn: $settings.cameraOverlay)
                }
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Toggle("Save Image to Photos", isOn: $settings.cameraOverlay)
                }
                HStack {
                    Image(systemName: "hand.raised")
                    Toggle("Set Camera Permissions", isOn: $settings.cameraOverlay)
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}
