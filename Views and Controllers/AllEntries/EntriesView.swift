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
    
    var entries: [Entry] {
        return feature.entry?.array as! [Entry]
    }
    
    var columns: GridItem = GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 20, alignment: .none)
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [columns] ) {
                ForEach(entries, id: \.self) { entry in
                    EntryCell(entry: entry)
                        .cornerRadius(8)
                }
                AddEntryCell()
                    .cornerRadius(8)
            }
        }
        .background(Color(.secondarySystemBackground))
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
    var df = DateFormatter()
    var entry: Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image("NewConditionUI")
                .resizable()
                .aspectRatio(1, contentMode: .fill)
            Text(df.string(from: entry.date))
                .bold()
            Text("Entry Number")
            Spacer()
        }
        //.aspectRatio(0.5, contentMode: .fit)
        .background(Color.white)
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
        .background(Color.white)
    }
}
