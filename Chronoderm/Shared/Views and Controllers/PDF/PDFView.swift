//
//  PDFView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 30/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI

struct PDFView: View {
    var vc: UIViewController?
    @State var passedCondition: SkinFeature?
    @State var entriesPerPage: Int
    @State var showNotes: Bool
    @State var showDate: Bool
    @State var activitySheetShown = false
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    
                    Spacer()
                    
                    ConfigurationVStack(entriesPerPage: self.$entriesPerPage, showNotes: self.$showNotes, showDate: self.$showDate, numberOfEntries: (self.passedCondition?.entry!.count)!)
                    
                    Spacer()
                    
                    PDFPreview(entriesPerPage: self.entriesPerPage, showNotes: self.showNotes, showDate: self.showDate)
                        .frame(width: geometry.size.height * 0.5 * 1/sqrt(2), height: geometry.size.height * 0.5)
                        .aspectRatio(contentMode: .fit)
                        .border(Color.primary)
                    
                    Spacer()
                    
               /*     if #available(iOS 13.4, *) {
                        generatePDFButton(generatePDF: self.drawPDF(), activitySheetShown: $activitySheetShown)
                            .hoverEffect(.lift)
                    } else { */
                    generatePDFButton(generatePDF: self.drawPDF(), activitySheetShown: self.$activitySheetShown)
                  // }
                }
                .navigationBarTitle("Generate PDF")
                .navigationBarItems(trailing: Button("Done", action: { self.vc?.dismiss(animated: true, completion: nil) }))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func drawPDF() -> [Any] {
        print((passedCondition?.entry!.count)!)
        guard passedCondition != nil else { return [] }
        
        guard let entries = passedCondition?.entry?.sortedArray(using: [NSSortDescriptor(key: "date", ascending: true)]) as? [Entry] else { return []}
        let numberOfPages = Int((Double(entries.count) / Double(entriesPerPage)).rounded(.up))
        print(numberOfPages)
        // A4 size
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
            // Use this to get US Letter size instead
            // let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        // Attributes for title text
        let titleAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.init(name: "HelveticaNeue-Bold", size: 36)!]
        
        // Attributes for date text
        let dateTextAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.init(name: "HelveticaNeue-Bold", size: 12)!]
        
        // Attributes for note text
        let entryTextAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.init(name: "Helvetica Neue", size: 12)!]
        
        // Attributes for footer text
        let footerAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.init(name: "Helvetica Neue", size: 12)!, .foregroundColor: UIColor.systemGray]
        
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            for pageNumber in 1...numberOfPages {
                context.beginPage()
                
                var titleDrawLocation = CGRect(x: 50, y: 40, width: 0, height: 0)
                // Title at top of first page of PDF.
                if pageNumber == 1 {
                    let title = "Report on \(passedCondition!.name!)\n"
                    titleDrawLocation = CGRect(x: 50, y: 50, width: 500, height: 36)
                    title.draw(in: titleDrawLocation, withAttributes: titleAttributes)
                }
                
                // Footer
                let footer = "Created using Chronoderm"
                let footerDrawLocation = CGRect(x: 50, y: 800, width: 500, height: 20)
                footer.draw (in: footerDrawLocation, withAttributes: footerAttributes)
                
                // Entries
                // Generate entry CGRects array, to store where on the page the entries will be. Available space is calculated as follows:
                // x: the same inset as the title.  y: 10 points below the title.  width: the width of the page, plus equal margins on either side.  height: the remaining space below the title, ending at the start of the footer.  The rectHeight formula will ensure that there is a space before the footer.
                var entryRects: [CGRect] = []
                let availableSpaceRect = CGRect(x: titleDrawLocation.minX, y: titleDrawLocation.maxY + 10, width: pageRect.width - 2 * titleDrawLocation.minX, height: (footerDrawLocation.minY) - (titleDrawLocation.maxY + 10))
                
                // The width of each entry rect is equal to the width of the available space.  The height is equal to the available space height, divided by the number of entries, accounting for a 10 point space after the rect (subtracted from the height).
                let rectWidth = availableSpaceRect.width
                let rectHeight = (availableSpaceRect.height / CGFloat(entriesPerPage)) - 10
                for entryLocationIndex in 1 ... entriesPerPage {
                    let rect = CGRect(x: availableSpaceRect.minX, y: (CGFloat(entryLocationIndex - 1) * rectHeight) + availableSpaceRect.minY, width: rectWidth, height: rectHeight)
                    entryRects.append(rect)
                }
                
                // For each entry
                for (index, entry) in entries.enumerated() {
                    // Check if the entry is in this page
                    if Int((Double(index + 1) / Double(entriesPerPage)).rounded(.up)) == pageNumber {
                        let entryDate = entry.date
                        let entryAttachment = entry.image?.anyObject() as! Attachment
                        let entryPhoto = UIImage(data: entryAttachment.fullImage!.fullImage!)
                        let entryNotes = self.showNotes ? entry.notes! : ""
                        
                        var dateDrawLocation: CGRect
                        var photoDrawLocation: CGRect
                        var notesDrawLocation: CGRect
                        
                        let entryRect = entryRects[(index) % entriesPerPage]
                        print("Index - 1 = \(index), entries per page = \(entriesPerPage), Remainder = \((index) % entriesPerPage)")
                        dateDrawLocation = CGRect(x: entryRect.minX, y: entryRect.minY, width: entryRect.width, height: 14)
                        photoDrawLocation = CGRect(x: entryRect.minX, y: dateDrawLocation.maxY + 10, width: min(rectHeight - (dateDrawLocation.height + 10), rectWidth * 0.6), height: min(rectHeight - (dateDrawLocation.height + 10), rectWidth * 0.6))
                        notesDrawLocation = CGRect(x: photoDrawLocation.maxX + 20, y: photoDrawLocation.minY, width: entryRect.maxX - photoDrawLocation.maxX + 20, height: 200)
                        
                        // Set the size of the image
                        let entryFormattedPhoto = NSTextAttachment()
                        entryFormattedPhoto.image = entryPhoto
                        entryFormattedPhoto.bounds = setImageHeight(textAttachment: entryFormattedPhoto, height: photoDrawLocation.height)
                        /*
                        switch entriesPerPage {
                        case 1:
                            dateDrawLocation = CGRect(x: 50, y: titleDrawLocation.maxY + 10, width: 500, height: 12)
                            photoDrawLocation = CGRect(x: 50, y: dateDrawLocation.maxY + 10, width: 200, height: 200)
                            notesDrawLocation = CGRect(x: photoDrawLocation.maxX + 20, y: photoDrawLocation.minY, width: 400, height: 200)
                            /*
 */
                        default:
                            continue
                        }*/
                        DateFormatter.localizedString(from: entryDate, dateStyle: .full, timeStyle: .medium).draw (in: dateDrawLocation, withAttributes: dateTextAttributes)
                        NSAttributedString(attachment: entryFormattedPhoto).draw (in: photoDrawLocation)
                        entryNotes.draw (in: notesDrawLocation, withAttributes: entryTextAttributes)
                    }
                }
                
                
            }
            
            
            
        }
            /*
            // Cycle through each entry
            for entry in entries {
                let entryDate = entry.date
                let entryAttachment = entry.image?.anyObject() as! Attachment
                let entryPhoto = UIImage(data: entryAttachment.fullImage.fullImage)!
                let entryNotes = self.showNotes ? "\(entry.notes!) \n" : ""
                
                let entryFormattedDate = NSAttributedString(
                    string: DateFormatter.localizedString(from: entryDate, dateStyle: .full, timeStyle: .medium) + "\n",
                    attributes: entryTextAttributes as [NSAttributedString.Key : Any])
                
                let entryFormattedPhoto = NSTextAttachment()
                entryFormattedPhoto.image = entryPhoto
                entryFormattedPhoto.bounds = setImageHeight(textAttachment: entryFormattedPhoto, height: 200)
                
                let entryFormattedText = NSAttributedString(string: "\n" + entryNotes + "\n \n", attributes: entryTextAttributes as [NSAttributedString.Key : Any])
                
                formattedTitle.append(entryFormattedDate)
                formattedTitle.append(NSAttributedString(attachment: entryFormattedPhoto))
                formattedTitle.append(entryFormattedText)
            } */
        
        
        return [data]
        
    }
    
    func setImageHeight(textAttachment: NSTextAttachment, height: CGFloat) -> CGRect {
        guard let image = textAttachment.image else { return CGRect(x: 0, y: 0, width: 0, height: 0)}
        let ratio = image.size.width / image.size.height
        let bounds = CGRect(x: 0, y: 0, width: ratio * height, height: height)
        return bounds
    }
}

struct PDFView_Previews: PreviewProvider {
    static var previews: some View {
        PDFView(vc: nil, passedCondition: nil, entriesPerPage: 1, showNotes: true, showDate: true)
    }
}

struct ConfigurationVStack: View {
    @Binding var entriesPerPage: Int
    @Binding var showNotes: Bool
    @Binding var showDate: Bool
    var numberOfEntries: Int
    var body: some View {
        VStack {
            Stepper(value: $entriesPerPage, in: 1 ... min(6,numberOfEntries )) {
                VStack {
                    CompatibleLabel(symbolName: "square.fill.text.grid.1x2", text: "Number of entries per page: \(entriesPerPage.description)")
                }
            }
            Toggle(isOn: $showNotes) {
                CompatibleLabel(symbolName: "text.alignleft", text: "Show Notes")
            }
            Toggle(isOn: $showDate) {
                CompatibleLabel(symbolName: "calendar", text: "Show Date")
            }
            
        }
        .padding()
    }
}

struct generatePDFButton: View {
    var generatePDF: [Any]
    @Binding var activitySheetShown: Bool
    var body: some View {
        Button(action: {self.activitySheetShown = true}) {
            CompatibleLabel(symbolName: "doc.richtext", text: "Generate PDF")
                .font(.title)
                .foregroundColor(.white)
        }
        .padding(10.0)
        .background(Color.blue)
        .cornerRadius(8.0)
        .padding()
        .popover(isPresented: $activitySheetShown, arrowEdge: .bottom) {
            ActivityViewController(isPresented: self.$activitySheetShown, activityItems: self.generatePDF)
                .frame(minWidth: 320, minHeight: 500)
        }
    }
}
