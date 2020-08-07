//
//  RemindersTableViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 14/08/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit
import UserNotifications
import CoreData

class RemindersTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    // MARK: - Outlets
    
    @IBOutlet var remindersOnSwitch: UISwitch!
    @IBOutlet var frequencyPicker: UIPickerView!
    @IBOutlet var frequencyLabel: UITableViewCell!
    
    @IBOutlet var timePickerCell: UITableViewCell!
    let timePickerCellIndexPath = IndexPath(row: 1, section: 1)
    let timeLabelCellIndexPath = IndexPath(row: 0, section: 1)
    var timeLabelCellSelected = false
    @IBOutlet var timePicker: UIDatePicker!
    @IBOutlet var timeLabel: UILabel!
    
    @IBOutlet var mondayCell: UITableViewCell!
    @IBOutlet var tuesdayCell: UITableViewCell!
    @IBOutlet var wednesdayCell: UITableViewCell!
    @IBOutlet var thursdayCell: UITableViewCell!
    @IBOutlet var fridayCell: UITableViewCell!
    @IBOutlet var saturdayCell: UITableViewCell!
    @IBOutlet var sundayCell: UITableViewCell!
    
    
    var managedObjectContext: NSManagedObjectContext!
    var previous: EntriesCollectionViewController!
    
    var daysSelected = [1: false, 2: false, 3: false, 4: false, 5: false, 6: false, 7: false] // 1 = Monday, 2 = Tuesday, 7 = Sunday, etc
    var timeSelected: Date?
    var remindersOn: Bool = false
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // frequencyPicker.delegate = self
        getReminders()
        configureView()
    }
    
    // MARK: - Model
    var passedCondition: SkinFeature?
    
    func getReminders() {
        
        guard let settings = passedCondition?.notificationSettings else { return }
        
        self.remindersOn = settings.remindersOn
        guard settings.remindersOn == true else { return }
        self.daysSelected[1] = settings.monday
        self.daysSelected[2] = settings.tuesday
        self.daysSelected[3] = settings.wednesday
        self.daysSelected[4] = settings.thursday
        self.daysSelected[5] = settings.friday
        self.daysSelected[6] = settings.saturday
        self.daysSelected[7] = settings.sunday
        self.timePicker.date = settings.time!
    }
    
    
    // MARK: - Notifications
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .sound]
    
    
    func setNotification() {
        //Request authorisation
        center.requestAuthorization(options: options) {
          (granted, error) in
            if !granted {
              print("Authorisation not granted")
            }
        }

    // Check authorisation
        center.getNotificationSettings { (settings) in
          if settings.authorizationStatus != .authorized {
            // Notifications not allowed
          }
        }
        
    // Clear old notifications
        let notifications = passedCondition!.notification
        var notificationArrayString: [String] = []
        for notification in notifications! {
            let notificationAsUUID = notification as! ConditionNotification
            notificationArrayString.append(notificationAsUUID.identifier!.uuidString)
        }
        center.removePendingNotificationRequests(withIdentifiers: notificationArrayString)
        for notification in notifications! {
            managedObjectContext.delete(notification as! NSManagedObject)
        }
        center.removeAllPendingNotificationRequests()
    
    // Create Notification
        let content = UNMutableNotificationContent()
        content.title = "Add Entry for \(passedCondition!.name!)"
        content.body = (passedCondition!.areaOfBody != "" ? "See how your \(passedCondition!.areaOfBody?.lowercased() ?? "skin") has changed" : "See how your skin has changed")
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "New entry reminder"
        content.threadIdentifier = passedCondition!.uuid!.uuidString
    
    // Schedule notification
        for (day, value) in daysSelected {
            guard value == true else { continue }
            let time = timePicker.date
            
            // Configure the recurring date.
            let calendar = Calendar.current
            var dateComponents = calendar.dateComponents([.hour, .minute], from: time) // Gets date components from date (time)
            dateComponents.weekday = day + 1 // Sets notification day
            if dateComponents.weekday == 8 { dateComponents.weekday = 0 } // If Sunday, loop back to 0
            dateComponents.timeZone = .current
               
            // Create the trigger as a repeating event.
            let trigger = UNCalendarNotificationTrigger(
                     dateMatching: dateComponents, repeats: true)
            
            // Create request
            let uuid = UUID()
            let request = UNNotificationRequest(identifier: uuid.uuidString,
                        content: content, trigger: trigger)
            
            // Save request in Core Data
            let CDnotification = ConditionNotification(context: managedObjectContext)
            CDnotification.condition = passedCondition!
            CDnotification.identifier = uuid

            // Schedule the request with the system.
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.add(request) { (error) in
               if error != nil {
                  // Handle any errors.
               }
            }
        }
        
        // Save Settings
        let settings = NotificationSettings(context: managedObjectContext)
        settings.setValue(true, forKey: "remindersOn")
        settings.setValue(daysSelected[1], forKey: "monday")
        settings.setValue(daysSelected[2], forKey: "tuesday")
        settings.setValue(daysSelected[3], forKey: "wednesday")
        settings.setValue(daysSelected[4], forKey: "thursday")
        settings.setValue(daysSelected[5], forKey: "friday")
        settings.setValue(daysSelected[6], forKey: "saturday")
        settings.setValue(daysSelected[7], forKey: "sunday")
        settings.setValue(timePicker.date, forKey: "time")
        passedCondition?.notificationSettings = settings
        
        updateCoreData()
    }
    
    // MARK: - Actions
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        if remindersOn == true {
            setNotification()
        } else {
            // Clear notifications
            let notifications = passedCondition!.notification
            var notificationArrayString: [String] = []
            for notification in notifications! {
                let notificationAsUUID = notification as! ConditionNotification
                notificationArrayString.append(notificationAsUUID.identifier!.uuidString)
            }
            center.removePendingNotificationRequests(withIdentifiers: notificationArrayString)
            for notification in notifications! {
                managedObjectContext.delete(notification as! NSManagedObject)
            }
            center.removeAllPendingNotificationRequests()
            
            // remove notification settings
            let settings = NotificationSettings(context: managedObjectContext)
            settings.setValue(false, forKey: "remindersOn")
            passedCondition?.notificationSettings = settings
            updateCoreData()
        }
        previous.setReminderButton()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func timePickerChanged(_ sender: Any) {
        updateDates()
        center.getPendingNotificationRequests(completionHandler: { requests in
            for request in requests {
                print(request)
            }
        })
    }
    
    @IBAction func remindersSwitchToggled(_ sender: Any) {
        remindersOn = remindersOnSwitch.isOn
        tableView.reloadData()
    }
    
    
    func configureView() {
        remindersOnSwitch.isOn = remindersOn
        mondayCell.accessoryType =      daysSelected[1]! ? .checkmark : .none
        tuesdayCell.accessoryType =     daysSelected[2]! ? .checkmark : .none
        wednesdayCell.accessoryType =   daysSelected[3]! ? .checkmark : .none
        thursdayCell.accessoryType =    daysSelected[4]! ? .checkmark : .none
        fridayCell.accessoryType =      daysSelected[5]! ? .checkmark : .none
        saturdayCell.accessoryType =    daysSelected[6]! ? .checkmark : .none
        sundayCell.accessoryType =      daysSelected[7]! ? .checkmark : .none
        updateDates()
    }
    
    func updateDates() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        
        timeLabel.text = dateFormatter.string(from: timePicker.date)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            let cell = tableView.cellForRow(at: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
            daysSelected[indexPath.row + 1]!.toggle()
            cell?.accessoryType = daysSelected[indexPath.row + 1]! ? .checkmark : .none
        }
        
        if indexPath == timeLabelCellIndexPath {
            tableView.deselectRow(at: indexPath, animated: true)
            timeLabelCellSelected.toggle()
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath == timePickerCellIndexPath {
            return timeLabelCellSelected ? 216 : 0
        } else {
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if remindersOn == false {
            if section != 0 {
                return 0
            } else {
                return UITableView.automaticDimension
            }
        } else {
            return UITableView.automaticDimension
        }
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if remindersOn == false {
            return 1
        } else {
            return 3
        }
    }
    /*
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    */
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "day", for: indexPath)
        if indexPath.section == 3 {
            cell.accessoryType = daysSelected[indexPath.row + 1]! ? .checkmark : .none
        }
        // Configure the cell...

        return cell
    }
    */
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    
    // MARK: - Picker view data source
    
    let pickerOptions = ["Weekly", "Daily"]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerOptions[row]
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Core Data
    
    func updateCoreData() {
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }

}
