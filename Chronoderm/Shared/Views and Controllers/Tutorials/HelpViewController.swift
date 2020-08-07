//
//  AboutViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 21/08/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController {
    
    @IBOutlet var helpTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentPage = pages[currentPageNo]
        configureView()
        // Do any additional setup after loading the view.
    }
    
    // MARK: - Model
    let pages = HelpPages.pages
    
    var currentPageNo = 0 {
        didSet {
            currentPage = pages[currentPageNo]
            configureView()
        }
    }
    
    var currentPage: helpPage? = nil
    
    // MARK: - Configure View
    func configureView() {
        helpTextView.font = UIFont.preferredFont(forTextStyle: .body)
        self.title = currentPage?.title
        helpTextView.attributedText = currentPage?.generateBody(width: view.bounds.width)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showContents" {
            guard let controller = segue.destination as? HelpContentsTableViewController else { return }
            controller.helpVC = self
        }
    }
    
    // MARK: - NSUserActivity
    var NSUserActivityPresent = false
    func startUserActivity() {
        let activity = NSUserActivity(activityType: "com.Baughan.Chronoderm.help")
        activity.userInfo = ["currentPageNo": currentPageNo]
        userActivity = activity
        userActivity?.becomeCurrent()
        
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        guard let pageNo: Int = activity.userInfo?["currentPageNo"] as? Int else { return }
        currentPageNo = pageNo
    }
}
