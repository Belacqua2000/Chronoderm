//
//  DetailViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 15/07/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit
import CoreData

protocol SyncEntry {
    func sendToCEVC(currentEntry: Int)
}

class DetailViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Outlets
    var managedObjectContext: NSManagedObjectContext!
    
    @IBOutlet var editButton: UIBarButtonItem!
    
    @IBOutlet var entryDateLabelSuperView: UIVisualEffectView!
    @IBOutlet var entryDateLabel: UILabel!
    
    @IBOutlet weak var detailTitle: UINavigationItem!
    @IBOutlet var entryImageView: UIImageView!
    @IBOutlet var entryTextSuperView: UIVisualEffectView!
    @IBOutlet var entryTextView: UITextView!
    
    @IBOutlet var previousButton: UIBarButtonItem!
    @IBOutlet var nextButton: UIBarButtonItem!
    
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var deleteButton: UIBarButtonItem!
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewLayouts()
        configureViewForEntry()
        updatePreviousNextButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        configureForMac(animated)
    }
    
    var delegate: SyncEntry?
    
    //MARK: - Model

    var currentEntry: Entry? {
        didSet {
            configureViewForEntry()
        }
    }
    var sortedEntries: [Entry] = []
    
    var currentEntryNumber: Int = 0 {
        didSet {
            currentEntry = sortedEntries[currentEntryNumber]
            updatePreviousNextButtons()
        }
    }
    var totalEntries: Int = 0
    
    //MARK: - Interface
    
    var interfaceIsVisible = true
    
    func configureViewLayouts() {
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
        self.scrollView.contentSize = self.entryImageView.frame.size
        self.scrollView.delegate = self
        entryTextSuperView.layer.cornerRadius = 10.0
        entryDateLabelSuperView.layer.cornerRadius = 10.0
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.entryImageView
    }
    
    func configureViewForEntry() {
        // This function is called through didSet on currentEntry, which will trigger during segue before view is loaded when outlets not configured
        guard isViewLoaded else { return }
        // Update the user interface for the detail item.
        guard let entry = currentEntry else { return }
        // Set title
        self.title = "Entry \(currentEntryNumber + 1)"
        // Set date text view
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        entryDateLabel.text = dateFormatter.string(from: entry.date)
        
        // Set image
        if let entryAttachment = entry.image?.anyObject() as? Attachment {
            if let entryImage = UIImage(data: entryAttachment.fullImage!.fullImage!) {
                UIView.transition(with: entryImageView, duration: 0.5, options: [.transitionCrossDissolve], animations: ({
                    self.entryImageView.image = entryImage
                }), completion: nil)
            }
        } else {
            entryImageView.image = nil
        }
        
        // Set notes label
        entryTextView.text = entry.notes
    }
    
    
    // MARK: - Actions
    
    @objc func toggleInterface() {
        let hideAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut, animations: {self.entryDateLabelSuperView.alpha = 0; self.entryTextSuperView.alpha = 0})
        let showAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut, animations: {self.entryDateLabelSuperView.alpha = 1; self.entryTextSuperView.alpha = 1})
        switch interfaceIsVisible {
        case true:
            interfaceIsVisible = false
            hideAnimator.startAnimation()
        case false:
            interfaceIsVisible = true
            showAnimator.startAnimation()
        }
    }
 
    func updatePreviousNextButtons() {
        guard isViewLoaded else { return }
        // Set buttons to enabled if multiple condition entries present
        if currentEntryNumber == 0 {
            previousButton.isEnabled = false
        } else {
            previousButton.isEnabled = true
        }
        
        if currentEntryNumber >= totalEntries - 1 {
            nextButton.isEnabled = false
        } else {
            nextButton.isEnabled = true
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    let detailViewKeyCommands = [UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: .command, action: #selector(previousButtonPressed(_:))), UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .command, action: #selector(nextButtonPressed(_:)))]
    
    /*
    override var keyCommands: [UIKeyCommand]? {
        detailViewKeyCommands[0].discoverabilityTitle = "Next Condition"
        detailViewKeyCommands[1].discoverabilityTitle = "Previous Condition"
        return detailViewKeyCommands
    }*/
    
    @IBAction func viewTapped( sender: Any) {
        toggleInterface()
    }
    
    @IBAction func previousButtonPressed(_ sender: Any) {
        guard currentEntryNumber > 0 else { return }
        currentEntryNumber -= 1
        //syncCEVC(offset: -1)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        guard currentEntryNumber < totalEntries - 1 else {return}
        currentEntryNumber += 1
        //syncCEVC(offset: 1)
    }
    /*
    func syncCEVC(offset: Int) {
        currentEntry = sortedEntries[currentEntryNumber]
        configureViewForEntry()
        masterVC?.syncVC(offset: offset)
    }*/

    @IBAction func deleteEntry(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Delete Entry", message: "Deleting an entry is permanent.  Are you sure you would like to continue?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Default action"), style: .destructive, handler: { _ in
            NSLog("The \"Delete\" alert occured.")
            self.delete()
            self.unwindToConditionEntries(self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Block needed to present as popover on iPad - crashes otherwise as Action Sheets unsupported
        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func delete() {
        guard let entry = currentEntry else { return }
        managedObjectContext.delete(entry)
    }
    
    @IBAction func actionButtonPressed(_ sender: UIBarButtonItem) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: currentEntry!.date) + "\n"
        let uiimage = currentEntry?.image?.anyObject() as! Attachment
        let image = uiimage.fullImage!.fullImage!
        var notes = currentEntry?.notes
        if notes != "" {
            notes = "\n" + currentEntry!.notes!
        }
        
        let activityView = UIActivityViewController(activityItems: [date, image, notes!], applicationActivities: nil)
        
        if let popoverPresentationController = activityView.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }
        
        self.present(activityView, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation
    
    // Sends the currently displayed entry to the Edit Entry view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editEntrySegue" {
            let controller = (segue.destination as! UINavigationController).topViewController as! AddEntryTableViewController
            guard let object = currentEntry else {return}
            controller.title = "Edit Entry"
            controller.passedEntry = object
            // Set previous photo
            if currentEntryNumber > 0 {
                let previousEntry = sortedEntries[currentEntryNumber - 1]
                let attachment = previousEntry.image?.anyObject() as? Attachment
                controller.previousPhoto = UIImage(data: attachment!.fullImage!.fullImage!)
            }
        }
        if segue.identifier == "showReminders" {
            let controller = (segue.destination as! UINavigationController).topViewController as! RemindersTableViewController
            controller.passedCondition = self.currentEntry?.condition
            controller.managedObjectContext = self.managedObjectContext
        }
        if segue.identifier == "markup" {
            let controller = segue.destination as! DrawingViewController
            controller.image = self.entryImageView.image
        }
    }
    
    // Get the new entry details from Edit Entry View
    @IBAction func unwindFromAddEntry(for unwindSegue: UIStoryboardSegue) {
        guard let addEntryTableViewController = unwindSegue.source as? AddEntryTableViewController else {return}
            
        guard let newEntryDate = addEntryTableViewController.newEntryDate else {return}
        guard let newEntryNotes = addEntryTableViewController.newEntryNotes else {return}
        guard let entry = currentEntry else {return}
        
        var uuid: UUID?
        
        uuid = entry.uuid
        if uuid == nil {
            uuid = UUID()
            entry.setValue(uuid, forKey: "uuid")
        }
        
        entry.setValue(newEntryDate, forKey: "date")
        entry.setValue(newEntryNotes, forKey: "notes")
        
        if let newEntryImage = addEntryTableViewController.newEntryPhoto {
            
            if let oldImages = entry.image?.allObjects as? [Attachment] {
                for image in oldImages {
                    managedObjectContext.delete(image)
                }
            }
            
            let attachment = Attachment(context: managedObjectContext)
    
            let thumbnail = newEntryImage.jpegData(compressionQuality: 0.5)
            let id = NSTimeIntervalSince1970
            
            attachment.setValue(thumbnail, forKey: "thumbnail")
            attachment.setValue(id, forKey: "imageID")
            
            
            let imageData = ImageData(context: managedObjectContext)
            
            let fullImage = newEntryImage.jpegData(compressionQuality: 1.0)
            
            imageData.setValue(fullImage, forKey: "fullImage")
            
            
            attachment.setValue(imageData, forKey: "fullImage")
            
            entry.addToImage(attachment)
        }
        
        updateCoreData()
        configureViewForEntry()
    }
    
    // Unwinds to Entries View
    @IBAction func unwindToConditionEntries(_ sender: Any) {
        performSegue(withIdentifier: "unwindToConditionEntries", sender: self)
    }
    
    // MARK: - Mac
    func configureForMac(_ animated: Bool) {
        #if targetEnvironment(macCatalyst)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.setToolbarHidden(true, animated: animated)
        #endif
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

