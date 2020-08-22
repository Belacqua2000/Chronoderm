//
//  Help.swift
//  Chronoderm
//
//  Created by Nick Baughan on 21/08/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Help Page Struct

struct helpPage: Identifiable {
    var id: Int
    
    let title: String
    let content: [HelpPageContent]?
    let bodyItems: [Any]
    // This function generates the body string, it accepts a view width as input to adjust the size of image
    mutating func generateBody(width: CGFloat) -> NSMutableAttributedString {
        let string: NSMutableAttributedString = NSMutableAttributedString(string: "")
        for item in bodyItems {
            switch item {
            case is NSAttributedString:
                string.append(item as! NSAttributedString)
            case is String:
                string.append(NSAttributedString(string: item as! String))
            case is NSTextAttachment:
                // resize the text attachment to match the width of the screen
                let sizedTextAttachment = setBounds(attachment: item as! NSTextAttachment, width: width)
                string.append(NSAttributedString(attachment: sizedTextAttachment))
            case is UIImage:
                let textAttachment = NSTextAttachment()
                // add image to the text attachment
                textAttachment.image = (item as! UIImage)
                // resize the text attachment to match width of the screen
                let sizedTextAttachment = setBounds(attachment: textAttachment, width: width)
                // add text attachment to the string
                string.append(NSAttributedString(attachment: sizedTextAttachment))
            default:
                continue
            }
        }
        if #available(iOS 13.0, *) {
            string.addAttributes([.font: UIFont.preferredFont(forTextStyle: .body), .foregroundColor: UIColor.label], range: NSRange(location: 0, length: string.length))
        } else {
            string.addAttributes([.font: UIFont.preferredFont(forTextStyle: .body)], range: NSRange(location: 0, length: string.length))
        }
        
        return string
    }
    
    // Func to set the bounds of the NSText attachment to the width of the device
    func setBounds(attachment: NSTextAttachment, width: CGFloat) -> NSTextAttachment {
        let ratio = attachment.image!.size.height / attachment.image!.size.width
        let adjustedWidth = width - 40
        //print(screenWidth)
        attachment.bounds = CGRect(x: 0, y: 0, width: adjustedWidth, height: adjustedWidth * ratio)
        return attachment
    }
    
    init(title: String, bodyItems: [HelpPageContent], id: Int) {
        self.title = title
        self.bodyItems = bodyItems
        self.id = id
        self.content = bodyItems
    }
}

// MARK: - Help Pages
struct HelpPages {
    static let pages = [welcome, addingConditions, addingEntries, settingReminders, exportingSkinFeatures]
}

struct HelpPageContent: Identifiable {
    enum contentType {
        case image
        case text
    }
    var id: Int
    let type: contentType
    let content: String
    
    init(id: Int, content: String, contentType: contentType) {
        self.id = id
        self.content = content
        self.type = contentType
    }
}

// MARK: - Welcome
private var welcome = helpPage(title: welcomeTitle, bodyItems: [welcome0], id: 0)

private var welcomeTitle: String = "Welcome"
private var welcome0: HelpPageContent = HelpPageContent(id: 0, content: """
Welcome to Chronoderm.  This app is designed to track areas of skin on your body over time.

By taking photos regularly, you can easily see how your injuries, scars, moles, or other skin conditions are changing.

Click on the book icon in the top right to choose a topic.
""", contentType: .text)

private var welcome1: HelpPageContent = HelpPageContent(id: 1, content: "App Icon Inside", contentType: .image)

// MARK: - Adding Conditions
private var addingConditions = helpPage(title: addingConditionsTitle, bodyItems: [addingConditions0, addingConditions1, addingConditions2, addingConditions3], id: 1)

private var addingConditionsTitle: String = "Adding Skin Features to Monitor"
private var addingConditions0 = HelpPageContent(
    id: 0,
    content: """
The app can track a variety of \"Skin Features\".  Think of these as a notable area of skin on your body.

To add a new skin feature, press the '+' button in the toolbar at the top of the screen.

""",
    contentType: .text)

private var addingConditions1 = HelpPageContent(id: 1, content: "New Feature Button", contentType: .image)

private var addingConditions2 = HelpPageContent(
    id: 2,
    content: """
Each skin feature can be assigned a name, area of body, and start date.
""",
    contentType: .text)

private var addingConditions3 = HelpPageContent(id: 3, content: "New Feature Screen", contentType: .image)

// MARK: - Adding Entries
private var addingEntries = helpPage(title: addingEntriesTitle, bodyItems: [addingEntries1, addingEntries2, addingEntries3, addingEntries4, addingEntries5, addingEntries6], id: 2)

private var addingEntriesTitle: String = "Adding Entries"
private var addingEntries1 = HelpPageContent(
    id: 0,
    content: """
Each skin feature can multiple entries.  You can think of these as a snapshot of your skin at a particular time.

To create a new entry, first select a skin feature from the main screen.  Then press the 'Add Entry' button at the end of the entries.
""",
    contentType: .text)

private var addingEntries2 = HelpPageContent(id: 1, content: "New Entry Button", contentType: .image)

private var addingEntries3 = HelpPageContent(
    id: 2,
    content: """
Press "Add Photo."  This will launch the camera to allow you to take a photo.

An 'onion skin' effect will be present if you have previously recorded an entry for the skin feature.  This will help guide you to align the photo to the previous one.  The opacity of this can be adjusted using the slider.

You can adjust the flash, flip the camera, or turn on/off the grid to help align your photo.

To add a photo from your phone, press "Add From Library"
""",
    contentType: .text)

private var addingEntries4 = HelpPageContent(id: 3, content: "Add Photo Screen", contentType: .image)

private var addingEntries5 = HelpPageContent(
    id: 4,
    content: """
When chosen and cropped, select the time the photo was taken, and optionally add notes.  Notes are highly encouraged, as they can give context to how you felt, what you were doing at the time of composing the entry etc.
""",
    contentType: .text)

private var addingEntries6 = HelpPageContent(id: 5, content: "Add Entry Screen", contentType: .image)

// MARK: - Setting Reminders
private var settingReminders = helpPage(title: settingRemindersTitle, bodyItems: [settingReminders1, settingReminders2, settingReminders3], id: 3)

private var settingRemindersTitle: String = "Setting Reminders"
private var settingReminders1 = HelpPageContent(
    id: 0,
    content: """
It is possible to set reminders to take photos of your skin features.

To set reminders, click on a skin feature, and press the bell icon in the lower left.
""",
    contentType: .text)

private var settingReminders2 = HelpPageContent(
    id: 1, content: "Reminders Button", contentType: .image)

private var settingReminders3 = HelpPageContent(
    id: 2,
    content: """
After turning on the switch, you can choose a time and which days of the week you would like to be reminded on.

If setting reminders for the first time, it will ask you to for permission.
""",
    contentType: .text)

// MARK: - Exporting to PDF
private var exportingSkinFeatures = helpPage(title: exportingSkinFeaturesTitle, bodyItems: [exportingSkinFeatures1, exportingSkinFeatures2, exportingSkinFeatures3], id: 4)

private var exportingSkinFeaturesTitle: String = "Exporting Skin Features as a PDF"
private var exportingSkinFeatures1 = HelpPageContent(
    id: 0,
    content: """
Chronoderm makes it incredibly easy to generate a PDF summary of your skin feature.  This is useful to share how your skin has changed over time with health and care professionals or family members.

To generate a PDF, first select a skin feature.
On iOS/iPadOS: click on the symbol of the document in the toolbar at the bottom of the screen.
On macOS: click on the symbol of the document in the toolbar at the top of the window.
""",
    contentType: .text)

private var exportingSkinFeatures2 = HelpPageContent(id: 1, content: "PDF Button", contentType: .image)

private var exportingSkinFeatures3 = HelpPageContent(
    id: 2,
    content: """
The following screen will let you customise the following:
How many photos to show per A4 page.  The greater the number, the smaller the photos.
Whether to show notes entered by the user on the right hand side of each photo.
Whether to show the date which photo was taken.

Click the blue button at the bottom of the screen to generate the PDF.  You can choose whether to save it to a file, share using an app, or print it.
""",
    contentType: .text)
