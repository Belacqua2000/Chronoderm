//
//  AddEntryView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 08/07/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI
import CoreData

@available(iOS 14.0, *)
struct AddEntryView: View {
    @Environment(\.managedObjectContext) var context
    @Binding var viewIsPresented: Bool
    var vc: UIViewController?
    @State var entry: Entry?
    @State var image: UIImage?
    @State var date: Date
    @State var notes: String
    @ObservedObject var skinFeature: SkinFeature
    @State var addPhotoIsPresented: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button(action: {self.addPhotoIsPresented.toggle()}) {
                        (image == nil) ? Label("Add Photo", systemImage: "photo") : Label("Edit Photo", systemImage: "photo")
                    }
                    .fullScreenCover(isPresented: $addPhotoIsPresented, content: {
                        NavigationView() {
                            AddPhotoView(image: self.$image)
                                .navigationBarTitleDisplayMode(.inline)
                                .navigationBarItems(leading: Button("Cancel", action: {addPhotoIsPresented = false}))
                                .navigationTitle("Capture")
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    })
                    if image != nil {
                        Image(uiImage: image!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                Section {
                    // Ensure the entry date isn't before the start date
                    DatePicker(selection: $date, in: skinFeature.startDate!...) {
                        Label("Date and Time", systemImage: "calendar")
                    }
                    .datePickerStyle(GraphicalDatePickerStyle())
                   
                }
                Section(header: Text("Add Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 400.0)
                }
            }
            .navigationTitle("Add New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: close)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action:  self.saveEntry )
                    .disabled(image == nil)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func close() {
        if let vc = vc {
            vc.dismiss(animated: true, completion: nil)
        } else {
            viewIsPresented = false
        }
    }
    
    func saveEntry() {
        let entry: Entry
        var uuid: UUID?
        if self.entry != nil {
            entry = self.entry!
            uuid = entry.uuid
            deleteEntryPhotos(entry: entry)
        } else {
            entry = Entry(context: context)
        }
        
        let entryDate = date
        let entryNotes = notes
        
        if uuid == nil {
            uuid = UUID()
            entry.setValue(uuid, forKey: "uuid")
        }
        
        entry.setValue(entryDate, forKey: "date")
        entry.setValue(entryNotes, forKey: "notes")
        entry.condition = skinFeature
        
        if let entryImage = image {
            let attachment = Attachment(context: context)
    
            let thumbnail = entryImage.jpegData(compressionQuality: 0.5)
            let id = NSTimeIntervalSince1970
            
            attachment.setValue(thumbnail, forKey: "thumbnail")
            attachment.setValue(id, forKey: "imageID")
            attachment.setValue(entry, forKey: "entry")
            
            let imageData = ImageData(context: context)
            
            let fullImage = entryImage.jpegData(compressionQuality: 1.0)
            
            imageData.setValue(fullImage, forKey: "fullImage")
            
            attachment.setValue(imageData, forKey: "fullImage")
            
            entry.addToImage(attachment)
        }
        
        self.entry = entry
        if let vc = vc {
            vc.dismiss(animated: true, completion: nil)
        } else {
            viewIsPresented = false
        }
    }
    
    func deleteEntryPhotos(entry: Entry) {
        if let oldImages = entry.image?.allObjects as? [Attachment] {
            for image in oldImages {
                context.delete(image)
            }
        }
    }
    
}
/*
@available(iOS 14.0, *)
struct AddEntryView_Previews: PreviewProvider {
    @State static var viewIsPresented = true
    @State static var entry: Entry? = nil
    @State static var context: NSManagedObjectContext? = nil
    static var previews: some View {
        AddEntryView(viewIsPresented: $viewIsPresented, entry: entry, image: UIImage(named: "NewConditionUI"), date: Date(), notes: "", skinFeature: nil)
    }
}*/
