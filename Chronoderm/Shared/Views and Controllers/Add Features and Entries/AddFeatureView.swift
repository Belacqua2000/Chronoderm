//
//  AddFeatureView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 23/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI
import CoreData

struct AddFeatureView: View {
    var vc: UIViewController?
    @Environment(\.managedObjectContext) var context
    @State var editingSkinFeature: SkinFeature?
    @State var date: Date
    @State var featureName: String
    @State var featureArea: String
    @State var firstEntry: Entry?
    @Binding var isViewShown: Bool
    var body: some View {
        NavigationView {
            if #available(iOS 14.0, *) {
                SkinFeatureDetailForm(date: $date, featureName: $featureName, featureArea: $featureArea, close: {close()}, save: {save()}, firstEntry: $firstEntry)
                    .navigationTitle(Text("Add Feature"))
                    .navigationBarItems(leading:
                                            Button("Cancel", action: close)
                                            .padding(.all, 10.0)
                                            .hoverEffect(.automatic),
                                        trailing:
                                            Button("Done", action: save)
                                            .padding(.all, 10.0)
                                            .hoverEffect(.automatic)
                                            .disabled(featureName == ""))
            } else {
                SkinFeatureDetailForm(date: $date, featureName: $featureName, featureArea: $featureArea, close: {close()}, save: {save()}, firstEntry: $firstEntry)
                    .navigationBarTitle(editingSkinFeature == nil ? Text("Add Skin Feature") : Text("Edit Skin Feature"))
                    .navigationBarItems(leading:
                                            Button("Cancel", action: cancel),
                                        trailing:
                                            Button("Done", action: save)
                                            .disabled(featureName == ""))
            }
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func save() {
        if editingSkinFeature == nil {
            SkinFeature.create(in: context, name: featureName, area: featureArea, date: date)
        } else {
            SkinFeature.update(feature: editingSkinFeature!, in: context, name: featureName, area: featureArea, date: date)
        }
        close()
    }
    
    func cancel() {
        if firstEntry != nil {
            context.rollback()
        }
        close()
    }
    
    func close() {
        if let vc = vc {
            vc.presentedViewController?.dismiss(animated: true, completion: nil)
        } else {
            isViewShown = false
        }
    }
    
}

struct AddFeatureView_Previews: PreviewProvider {
    @State static var isShown: Bool = true
    static var previews: some View {
        AddFeatureView(date: Date(), featureName: "", featureArea: "", isViewShown: $isShown)
    }
}

struct SkinFeatureDetailForm: View {
    @Environment(\.managedObjectContext) var context
    @Binding var date: Date
    @Binding var featureName: String
    @Binding var featureArea: String
    @State var addEntryShown: Bool = false
    var close: () -> Void
    var save: () -> Void
    @Binding var firstEntry: Entry?
    var body: some View {
        Form {
            Section(footer: Text("E.g. Acne, ingrown toenail, cut finger.")) {
                HStack {
                    Image(systemName: "text.quote")
                    TextField("Name of feature for monitoring", text: $featureName)
                }
            }
            Section(footer: Text("E.g. Nose, left thigh, right wrist.")) {
                HStack {
                    Image(systemName: "figure.wave")
                    TextField("Area", text: $featureArea)
                }
            }
            Section(footer: Text("When did you first notice this?")) {
                DatePicker(selection: $date, in: ...Date(), displayedComponents: .date) {
                    CompatibleLabel(symbolName: "calendar", text: "Start Date")
                }
                
            }
            /*Button(action: {self.addEntryShown.toggle()}) {
                HStack {
                    Spacer()
                    Image(systemName: "photo")
                    Text("Add First Entry")
                    Spacer()
                }
            }
            .sheet(isPresented: $addEntryShown) {
             AddEntryView(context: self.$context, viewIsPresented: self.$addEntryShown, entry: self.$firstEntry, date: Date(), notes: "")
             }*/
            
            }
        #if targetEnvironment(macCatalyst)
        HStack {
            Spacer()
            Button("Cancel", action: {close()}).keyboardShortcut(.cancelAction)
            Button("Save", action: {save()}).keyboardShortcut(.defaultAction)
        }
        .padding()
        #endif
    }
    
    func addFirstEntry() {
        
    }
}
