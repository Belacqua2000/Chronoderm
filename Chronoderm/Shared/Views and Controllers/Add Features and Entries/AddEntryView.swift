//
//  AddEntryView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 08/07/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI
import CoreData

struct AddEntryView: View {
    @Binding var context: NSManagedObjectContext?
    @Binding var viewIsPresented: Bool
    @Binding var entry: Entry?
    @State var image: UIImage?
    @State var date: Date
    @State var notes: String
    @State var skinFeature: SkinFeature?
    @State var addPhotoIsPresented: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button(action: {self.addPhotoIsPresented.toggle()}) {
                        (image == nil) ? CompatibleLabel(symbolName: "photo", text: "Add Photo") : CompatibleLabel(symbolName: "photo", text: "Edit Photo")
                    }
                    .sheet(isPresented: $addPhotoIsPresented, content: {
                        NavigationView() {
                            AddPhotoView(image: self.$image)
                                .navigationBarItems(leading: Button("Cancel", action: {}))
                                .navigationBarTitle("Capture", displayMode: .inline)
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
                    DatePicker("Date and Time", selection: $date, in: skinFeature?.startDate!... ?? Date(timeIntervalSince1970: 0)...)
                }
                Section(header: Text("Add Notes")) {
                   /* if #available(iOS 14.0, *) {
                      //  TextEditor(text: $notes)
                    } else {*/
                        TextField("E.g. Pain? Bleeding? Itch? Discharge?", text: $notes)
                  //  }
                }
            }
            .navigationBarTitle("Add New Entry")
            .navigationBarItems(leading: Button("Cancel", action: {self.viewIsPresented = false}), trailing: Button("Done", action: { self.saveEntry() }))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func saveEntry() {
        let entry: Entry
        var uuid: UUID?
        if self.entry != nil {
            entry = self.entry!
            uuid = entry.uuid
            deleteEntryPhotos(entry: entry)
        } else {
            entry = Entry(context: context!)
        }
        
        let entryDate = date
        let entryNotes = notes
        
        if uuid == nil {
            uuid = UUID()
            entry.setValue(uuid, forKey: "uuid")
        }
        
        entry.setValue(entryDate, forKey: "date")
        entry.setValue(entryNotes, forKey: "notes")
        
        if let entryImage = image {
            let attachment = Attachment(context: context!)
    
            let thumbnail = entryImage.jpegData(compressionQuality: 0.5)
            let id = NSTimeIntervalSince1970
            
            attachment.setValue(thumbnail, forKey: "thumbnail")
            attachment.setValue(id, forKey: "imageID")
            attachment.setValue(entry, forKey: "entry")
            
            let imageData = ImageData(context: context!)
            
            let fullImage = entryImage.jpegData(compressionQuality: 1.0)
            
            imageData.setValue(fullImage, forKey: "fullImage")
            
            attachment.setValue(imageData, forKey: "fullImage")
            
            entry.addToImage(attachment)
        }
        
        self.entry = entry
        
        viewIsPresented = false
    }
    
    func deleteEntryPhotos(entry: Entry) {
        if let oldImages = entry.image?.allObjects as? [Attachment] {
            for image in oldImages {
                context!.delete(image)
            }
        }
    }
    
}

struct AddEntryView_Previews: PreviewProvider {
    @State static var viewIsPresented = true
    @State static var entry: Entry? = nil
    @State static var context: NSManagedObjectContext? = nil
    static var previews: some View {
        AddEntryView(context: $context, viewIsPresented: $viewIsPresented, entry: $entry, image: UIImage(named: "NewConditionUI"), date: Date(), notes: "")
    }
}
