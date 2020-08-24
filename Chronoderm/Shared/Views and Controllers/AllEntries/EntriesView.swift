//
//  EntriesView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 19/08/2020.
//

import SwiftUI

@available(iOS 14.0, *)
struct EntriesView: View {
    @Environment(\.managedObjectContext) var context
    @ObservedObject var feature: SkinFeature
    
    @State var isNewEntryShown: Bool = false
    
    var entries: [Entry] {
        return feature.entry?.array as! [Entry]
    }
    
    var columns: GridItem = GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 20, alignment: .none)
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Area of Body:")
                    Text(feature.areaOfBody!)
                    Spacer()
                }
                HStack {
                    Text("Start Date:")
                    Text(df.string(from: feature.startDate!))
                    Spacer()
                }
            }
            .padding()
            .foregroundColor(.white)
            .background(Color("Theme Colour 2"))
            LazyVGrid(columns: [columns] ) {
                ForEach(entries, id: \.self) { entry in
                    NavigationLink(destination: DetailView(skinFeature: feature)) {
                        EntryCell(entry: entry)
                            .cornerRadius(8)
                            .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                    }
                }
                Button {
                    isNewEntryShown = true
                } label: {
                    AddEntryCell()
                        .cornerRadius(8)
                        .sheet(isPresented: $isNewEntryShown, content: {
                            AddEntryView(viewIsPresented: $isNewEntryShown, date: Date(), notes: "", skinFeature: feature)
                        })
                        .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    
                } label: {
                    Image(systemName: "bell")
                }
            }
        }
        .navigationBarTitleDisplayMode(.automatic)
        .navigationTitle(feature.name!)
    }
    
    
    var df: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .long
        return df
    }
}

@available(iOS 14.0, *)/*
struct EntriesView_Previews: PreviewProvider {
    @State static var feature: SkinFeature? = nil
    static var previews: some View {
        EntriesView()
    }
}*/

struct EntryCell: View {
    var entry: Entry
    var thumbnail: Image? {
        guard let attachment = entry.image?.anyObject() as? Attachment else { return nil }
        guard let thumbnailData = attachment.thumbnail else { return nil }
        return Image(uiImage: UIImage(data: thumbnailData)!)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            thumbnail!
                .resizable()
                .aspectRatio(1, contentMode: .fill)
            Text(df.string(from: entry.date))
                .bold()
            Text("Entry Number")
            Spacer()
        }
        //.aspectRatio(0.5, contentMode: .fit)
        .background(Color(.secondarySystemBackground))
    }
    
    var df: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .short
        return df
    }
    
}

struct AddEntryCell: View {
    var body: some View {
        VStack{
            Spacer()
            Image(systemName: "plus")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .padding()
            Text("Add Entry")
            Spacer()
        }
        .background(Color(.secondarySystemBackground))
    }
}
