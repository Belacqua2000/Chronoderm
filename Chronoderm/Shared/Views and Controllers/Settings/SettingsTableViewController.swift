//
//  SettingsTableViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 13/08/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

class SettingsTableViewController: UITableViewController {

    // MARK: - Variables
    var conditionsController: SkinFeaturesTableViewController?
    var saveToPhotosSubscriber: AnyCancellable?
    var showOverlaySubscriber: AnyCancellable?
    var showQuickActionsSubscriber: AnyCancellable?
    var indexSpotlightSubscriber: AnyCancellable?
    
    // MARK: - Outlets
    @IBOutlet var showCameraOverlaySwitch: UISwitch!
    @IBOutlet var saveToPhotosSwitch: UISwitch!
    
    @IBOutlet var showCameraOverlayCell: UITableViewCell!
    @IBOutlet var saveCapturedImageCell: UITableViewCell!
    
    
    @IBOutlet var showHomeActionsCell: UITableViewCell!
    @IBOutlet var quickActionsSwitch: UISwitch!
    
    @IBOutlet var indexSpotlightCell: UITableViewCell!
    @IBOutlet var indexSpotlightSwitch: UISwitch!
    
    @IBOutlet var leadingConstraints: [NSLayoutConstraint]!
    
    @IBOutlet var versionNumberLabel: UILabel!
    @IBOutlet var buildNumberLabel: UILabel!
    
    
    // MARK: - Life Cycle
    static func loadFromStoryboard() -> SettingsTableViewController? {
           let storyboard = UIStoryboard(name: "Main", bundle: .main)
           return storyboard.instantiateViewController(withIdentifier: "SettingsTableViewController") as? SettingsTableViewController
       }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setVersionNumbers()
        startNSUserActivity()
    }
    
    func setSubscriber() {
        saveToPhotosSubscriber = UserDefaults.standard
            .publisher(for: \.saveImageToPhotos, options: [.initial, .new])
            .assign(to: \.isOn, on: saveToPhotosSwitch)
        
        showOverlaySubscriber = UserDefaults.standard
            .publisher(for: \.CameraOverlayIsShown, options: [.initial, .new])
            .assign(to: \.isOn, on: showCameraOverlaySwitch)
        
        showQuickActionsSubscriber = UserDefaults.standard
            .publisher(for: \.showHomeQuickActions, options: [.initial, .new])
            .assign(to: \.isOn, on: quickActionsSwitch)
        
        indexSpotlightSubscriber = UserDefaults.standard
            .publisher(for: \.indexSpotlight, options: [.initial, .new])
            .assign(to: \.isOn, on: indexSpotlightSwitch)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set the scene title
        view.window?.windowScene?.title = "Settings"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.window?.windowScene?.userActivity = userActivity
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.userActivity = nil
        view.window?.windowScene?.userActivity = userActivity
        view.window?.windowScene?.title = nil
    }
    
    
    // MARK: - UITableView Delegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    // MARK: - Saving Settings
    
    let defaults = UserDefaults.standard
    
    func configureView() {
        setSubscriber()
        let cameraOverlayValue = defaults.bool(forKey: "CameraOverlayIsShown")
        showCameraOverlaySwitch.isOn = cameraOverlayValue
        
        let savePhotoValue = defaults.bool(forKey: "saveImageToPhotos")
        saveToPhotosSwitch.isOn = savePhotoValue
        
        let showQuickActionsValue = defaults.bool(forKey: "showHomeQuickActions")
        quickActionsSwitch.isOn = showQuickActionsValue
        
        let indexSpotlightValue = defaults.bool(forKey: "indexSpotlight")
        indexSpotlightSwitch.isOn = indexSpotlightValue
        
        if #available(iOS 13.0, *) {
            showCameraOverlayCell.imageView!.image = UIImage(systemName: "camera.on.rectangle")
            saveCapturedImageCell.imageView?.image = UIImage(systemName: "photo.on.rectangle")
            showHomeActionsCell.imageView?.image = UIImage(systemName: "rectangle.grid.1x2")
            indexSpotlightCell.imageView?.image = UIImage(systemName: "magnifyingglass")
            
            for constraint in leadingConstraints {
                constraint.constant = 40
            }
            updateViewConstraints()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case IndexPath(row: 2, section: 1):
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        case IndexPath(row: 1, section: 0):
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            return
        }
    }
    
    func setVersionNumbers() {
        let global = GlobalVariables()
        versionNumberLabel.text = global.currentVersion
        buildNumberLabel.text = global.currentBuild
    }
    
    
    @IBAction func cameraOverlaySwitchToggled(_ sender: Any) {
        let value = showCameraOverlaySwitch.isOn
        defaults.set(value, forKey: "CameraOverlayIsShown")
    }
    
    @IBAction func saveToPhotosSwitchToggled(_ sender: Any) {
        let value = saveToPhotosSwitch.isOn
        defaults.set(value, forKey: "saveImageToPhotos")
    }
    
    @IBAction func quickActionsSwitchToggled(_ sender: Any) {
        let value = quickActionsSwitch.isOn
        defaults.set(value, forKey: "showHomeQuickActions")
        if let conditionsVC = conditionsController {
            conditionsVC.addHomeScreenShortcutItems()
        }
    }
    
    @IBAction func indexAreasSwitchToggled(_ sender: Any) {
        let value = indexSpotlightSwitch.isOn
        defaults.set(value, forKey: "indexSpotlight")
        if let conditionsVC = conditionsController {
            conditionsVC.addToSpotlight()
        }
    }
    
    
    
    // MARK: - NSUserActivity
    
    var settingsUserActivity: NSUserActivity {
        let userActivity = NSUserActivity(activityType: "com.Baughan.Chronoderm.settings")
        userActivity.title = "Settings"
        return userActivity
    }
    
    func startNSUserActivity() {
        // NSUserActivity
        let activity = NSUserActivity(activityType: "com.Baughan.Chronoderm.settings")
        activity.title = "Settings"
        userActivity = activity
        userActivity?.becomeCurrent()
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        NSUserActivityPresent = true
    }
    var NSUserActivityPresent = false
    
    
    // MARK: - Navigation
    
    @IBSegueAction func tutorialSegue(_ coder: NSCoder) -> UIViewController? {
        let rootView = OnboardingView(vc: self)
        return UIHostingController(coder: coder, rootView: rootView)
    }
    
    @IBSegueAction func helpSegue(_ coder: NSCoder) -> UIViewController? {
        let rootView = HelpView()
        return UIHostingController(coder: coder, rootView: rootView)
    }
    
    

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
