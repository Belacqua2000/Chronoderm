//
//  AddConditionTableViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 15/07/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit

class AddConditionTableViewController: UITableViewController {
    
// MARK: - Outlets
    
    @IBOutlet var conditionTitle: UITextField!
    
    @IBOutlet var saveBarButton: UIBarButtonItem!
    
    @IBOutlet var conditionAreaOfBody: UITextField!
    
    @IBOutlet var conditionDateLabel: UILabel!
    
    @IBOutlet var conditionDatePicker: UIDatePicker!
    
    let conditionDateLabelIndexPath = IndexPath(row: 0, section: 2)
    let conditionDatePickerIndexPath = IndexPath(row: 1, section: 2)
    
    var conditionDatePickerShown: Bool = false {
        didSet {
            conditionDatePicker.isHidden = !conditionDatePickerShown
        }
    }
    
    var passedCondition: SkinFeature?
    var editingCondition = false
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        conditionDatePicker.maximumDate = Date()
        if editingCondition == true {
            configureEditMode()
        }
        updateSaveButton()
        updateDates()
        startNSUserActivity()
        if NSUserActivityPresent {
            configureLabels()
        }
    }
    
    func updateSaveButton() {
        saveBarButton.isEnabled = conditionTitle.text!.isEmpty ? false : true
    }

    //MARK: - Model
    
    var nameToSet: String?
    var areaToSet: String?
    var dateToSet: Date?
    
    
    var newConditionName: String? {
        guard let name: String = conditionTitle.text else {fatalError("No name")}
        
        return name
    }
    
    var newConditionArea: String? {
        guard let area: String = conditionAreaOfBody.text else {fatalError("No area")}
        
        return area
    }
    
    var newConditionDate: Date? {
        let date: Date = conditionDatePicker.date
        
        return date
    }
 
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table View Source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case conditionDatePickerIndexPath:
            if conditionDatePickerShown {
                return 216.0
            } else {
                return 0.0
            }
        default:
            return 44.0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath {
        case conditionDateLabelIndexPath:
            conditionDatePickerShown.toggle()
        default:
            break
        }
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    // MARK: - Actions
    func configureLabels() {
        conditionTitle.text = nameToSet
        conditionAreaOfBody.text = areaToSet
        conditionDatePicker.date = dateToSet!
    }
    
    func configureEditMode() {
        guard let condition = passedCondition else { print("No condition"); return }
        nameToSet = condition.name
        areaToSet = condition.areaOfBody
        dateToSet = condition.startDate
        configureLabels()
    }
    
    @IBAction func datePickerValueChanged(_ sender: Any) {
        updateDates()
    }
    
    @IBAction func conditionNameDidChange(_ sender: Any) {
        updateSaveButton()
    }
    
    @IBAction func TextEditingDidEnd(_ sender: UITextField) {
        updateUserActivityState(userActivity!)
    }
    
 
    func updateDates() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        conditionDateLabel.text = dateFormatter.string(from: conditionDatePicker.date)
    }
    
    // MARK: - NSUserActivity
    
    func startNSUserActivity() {
        // NSUserActivity
        let activity = NSUserActivity(activityType: "com.Baughan.Chronoderm.NewCondition")
        activity.title = "New Condition"
        activity.userInfo = ["name": conditionTitle.text!, "startDate": conditionDatePicker.date, "areaOfBody" : conditionAreaOfBody.text!]
        userActivity = activity
        userActivity?.becomeCurrent()
    }
    
    
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        activity.addUserInfoEntries(from: ["name": self.conditionTitle.text!, "startDate": self.conditionDatePicker.date, "areaOfBody": self.conditionAreaOfBody.text!])
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        guard let userInfo = activity.userInfo else { return }
        guard let importedName = userInfo["name"] as? String else { return }
        guard let importedDate = userInfo["startDate"] as? Date else { return }
        guard let importedArea = userInfo["areaOfBody"] as? String else { return }
        
        nameToSet = importedName
        dateToSet = importedDate
        areaToSet = importedArea
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
