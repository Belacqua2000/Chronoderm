//
//  Help.swift
//  Chronoderm
//
//  Created by Nick Baughan on 21/08/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit

// MARK: - Help Page Struct

struct helpPage {
    let title: String
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
    
    init(title: String, bodyItems: [Any]) {
        self.title = title
        self.bodyItems = bodyItems
    }
}

// MARK: - Help Pages
struct HelpPages {
    static let pages = [welcome, addingConditions, addingEntries, settingReminders]
}

// MARK: - Welcome
private var welcome = helpPage(title: welcomeTitle, bodyItems: [welcomeString1])

private var welcomeTitle: String = "Welcome"
private var welcomeString1 = """
Welcome to Chronoderm.  This app is designed to track areas of skin on your body over time.

By taking photos regularly, you can easily see how your injuries, scars, moles, or other skin conditions are changing.
"""



// MARK: - Adding Conditions
private var addingConditions = helpPage(title: addingConditionsTitle, bodyItems: [addingConditionsString1, addingConditionsImage1 ?? "", addingConditionsImage2 ?? ""])

private var addingConditionsTitle: String = "Adding Areas for Monitoring"
private var addingConditionsString1: String = """
The app can track a variety of \"Areas\".  Think of these as an area of skin on your body — e.g. 'Left big toenail', 'Inside right wrist', 'Back of neck'.

Each Condition can be assigned a name, area of body, and start date.

To add a new area, press the '+' button in the toolbar at the bottom of the screen in the 'Conditions' tab.

"""

private var addingConditionsImage1 = UIImage(named: "NewConditionButton")

private var addingConditionsImage2 = UIImage(named: "NewConditionUI")

// MARK: - Adding Entries
private var addingEntries = helpPage(title: addingEntriesTitle, bodyItems: [addingEntriesString1])

private var addingEntriesTitle: String = "Adding Entries"
private var addingEntriesString1: String = """
Each condition can multiple entries.  You can think of these as a snapshot of your skin at a particular time.

To create a new entry, first select a Condition from the main screen.  Then press the 'Add Entry' button in the toolbar at the bottom of the screen.

First, add a photo.  If using the camera, an 'onion skin' effect will be present, if you have already entered an entry for the condition, which will help guide you to align the photo to the one previously.  Then, select the time the photo was taken, and optionally add notes.  Notes are highly encouraged, as they can remind you in the future how you felt, what you were doing, etc. at the time of composing the entry.
"""

// MARK: - Setting Reminders
private var settingReminders = helpPage(title: settingRemindersTitle, bodyItems: [settingRemindersString1])

private var settingRemindersTitle: String = "Setting Reminders"
private var settingRemindersString1: String = """
It is possible to set reminders for different conditions in your body.
"""


private let welcomeHtml = """
<html>
    <body>
        <p>
            Welcome to Chronoderm.  This app is designed to track areas of skin on your body over time. <br> </br> By taking photos regularly, you can easily see how your injuries, scars, moles, or other visible artifacts are changing.
        </p>
        <p>
            <img src="file:///Settings tab icon 2x.png">
        </p>
    </body>
</html>
"""


