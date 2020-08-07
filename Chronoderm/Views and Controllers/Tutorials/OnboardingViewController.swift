//
//  OnboardingViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 05/09/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit

enum Pages {
    case pageZero
    case pageOne
    case pageTwo
}

class OnboardingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setText()
        setFooterHeight()
        startNSUserActivity()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if #available(iOS 13.0, *) {
            view.window?.windowScene?.userActivity = userActivity
        } else {
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.userActivity = nil
        if #available(iOS 13.0, *) {
            view.window?.windowScene?.userActivity = userActivity
        } else {
            // Fallback on earlier versions
        }
    }
    
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var customLabel: UILabel!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var bodyTextView: UITextView!
    @IBOutlet var footerTextView: UITextView!
    @IBOutlet var footerHeightConstraint: NSLayoutConstraint!
    
    
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func setText() {
        let primaryText = """
Your skin is a vital and complex part of your body.  It acts as a barrier to infections, can sense your environment, and regulate temperature.  Changes in your skin can act as an important indicator into your health.

Chronoderm is an app which can help you to keep track of visual changes to your skin.  Taking photos regularly can make it easier to see how your skin is changing.

Examples of skin features which you can monitor are:
\u{2022} Moles and freckles
\u{2022} Wounds and injuries
\u{2022} Rashes, acne, and rosacea

A customisable summary of your skin features can be generated to make it easy to share with others, such as healthcare professionals or family members.

To get started, press the + button in the bottom toolbar to track a new skin feature.

Entries can be added to each area of skin to allow you easily record how your skin looked, along with any additional notes.

For more detailed instructions, please see the help section within the settings menu.
"""
        let footnoteText = """
This app does not analyse your skin to give a diagnosis.  If you are worried about how your skin is changing, please seek advice from a healthcare professional.
This app is designed to be used by individuals for their personal use.
"""
        
        var primaryAttributed: NSMutableAttributedString
        var footnoteAttributed: NSMutableAttributedString
        
        if #available(iOS 13.0, *) {
            primaryAttributed = NSMutableAttributedString(string: primaryText, attributes: [.font: UIFont.preferredFont(forTextStyle: .body), .foregroundColor: UIColor.label])
        } else {
            primaryAttributed = NSMutableAttributedString(string: primaryText, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
        }
        
        if #available(iOS 13.0, *) {
            footnoteAttributed = NSMutableAttributedString(string: footnoteText, attributes: [.font: UIFont.preferredFont(forTextStyle: .footnote), .foregroundColor: UIColor.secondaryLabel])
            } else {
            footnoteAttributed = NSMutableAttributedString(string: footnoteText, attributes: [.font: UIFont.preferredFont(forTextStyle: .footnote)])
        }
        
        let fullAttributedString =  NSMutableAttributedString(attributedString: primaryAttributed)
        
        bodyTextView.attributedText = fullAttributedString
        footerTextView.attributedText = footnoteAttributed
    }
    
    func setFooterHeight() {
        
    }
    
    // MARK: - NSUserActivity
    
    var tutorialUserActivity: NSUserActivity {
        let userActivity = NSUserActivity(activityType: "com.Baughan.MyHealingTest.tutorial")
        userActivity.title = "Settings"
        return userActivity
    }
    
    func startNSUserActivity() {
        // NSUserActivity
        let activity = NSUserActivity(activityType: "com.Baughan.MyHealingTest.tutorial")
        activity.title = "Tutorial"
        userActivity = activity
        userActivity?.becomeCurrent()
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        NSUserActivityPresent = true
    }
    var NSUserActivityPresent = false
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


}
