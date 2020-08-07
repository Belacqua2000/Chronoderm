//
//  EntriesCollectionViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 25/03/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import UIKit
import CoreData
import SwiftUI
import Combine

private let reuseIdentifier = "Cell"

class EntriesCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    var previousController: SkinFeaturesTableViewController?
    var condition: SkinFeature? = nil
    var noCondition: Bool {
        return condition == nil
    }
    var sortOldest: Bool = true {
        didSet {
            
        }
    }
    private var remindersSubscriber: AnyCancellable?
    private var pdfSubscriber: AnyCancellable?
    private var toggleCompleteSubscriber: AnyCancellable?

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print(condition ?? "no condition")
        if noCondition {
            setEmptyInterface()
        } else {
            setInterface()
        }

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        //Flow layout delegate
        collectionView.collectionViewLayout = EntriesFlowLayout()
        collectionView.delegate = self
        collectionView.dragDelegate = self
        
        // Register notifications for toolbar/keycommand actions
        let notificationCenter = NotificationCenter.default
        remindersSubscriber = notificationCenter.publisher(for: .reminders)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { notification in
                self.showReminders()
            })
        notificationCenter.addObserver(self, selector: #selector(generatePDF), name: .createPDF, object: nil)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        configureForMac(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        setToolbarEnabled(isDisabled: noCondition)
        if #available(iOS 13.0, *) {
            view.window?.windowScene?.title! = condition?.name ?? "Skin Features"
        } else {
            // Fallback on earlier versions
        }
    }
    
    // MARK: - Outlets
    @IBOutlet var remindersBarButton: UIBarButtonItem!
    @IBOutlet var sortSegmentedControl: UISegmentedControl!
    
    @IBOutlet var pdfBarButton: UIBarButtonItem!
    
    // MARK: - UICollectionViewDataSource
    let itemsPerRow:CGFloat = 1
    let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if noCondition {
            return 0
        } else {
            // Returns the number of entries in the area, plus the one "add" cell
            return (fetchedResultsController?.fetchedObjects?.count ?? 0) + 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Need to calculate what the last indexPath is, as it will load the "add" cell.  If no entries, indexPath is [0,0].  If not, indexPath row will equal entries.count, as this starts from 1, and indexPath starts from zero.
        let lastIndexPath = IndexPath(row: fetchedResultsController?.fetchedObjects?.count ?? 0, section: 0)
        if indexPath == lastIndexPath {
            // If the last index path, load the Add Entry cell and format.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddEntryCell", for: indexPath) as! EntriesCollectionViewCell
            formatCell(cell)
            return cell
        } else {
            // For all other cells, load the standard entry cell, configure and format.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EntryCell", for: indexPath) as! EntriesCollectionViewCell
            if let entry = fetchedResultsController?.fetchedObjects?[indexPath.row] {
                configureCell(cell, withEntry: entry, atIndexPath: indexPath)
            }
            formatCell(cell)
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "entryInfo", for: indexPath) as! InfoCollectionReusableView
            if let condition = condition {
                view.areaLabel.text = "Area of body: \(condition.areaOfBody ?? "No area specified")"
                let df = DateFormatter()
                df.dateStyle = .medium
                view.dateLabel.text = "Start Date: \(df.string(from: condition.startDate!))"
                view.backgroundColor = UIColor.init(named: "Theme Colour 2")
            } else {
                view.areaLabel.text = ""
                view.dateLabel.text = ""
                view.backgroundColor = nil
                return view
            }
            return view
        default:
            assert(false)
        }
        
    }
    
    func formatCell(_ cell: EntriesCollectionViewCell) {
        // Cell styling
        cell.layer.cornerRadius = 10.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true

        /*
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath */
    }
    
    func configureCell(_ cell: EntriesCollectionViewCell, withEntry entry: Entry, atIndexPath indexPath: IndexPath) {
        let df = DateFormatter()
        df.dateStyle = .medium
        cell.cellDateLabel.text = df.string(from: entry.date)
        cell.cellEntryLabel.text = "Entry \(indexPath.row + 1)"
        if let image = entry.image?.anyObject() as? Attachment {
            cell.cellImageView?.contentMode = .scaleAspectFill
            cell.cellImageView?.image = UIImage(data: image.thumbnail!)
            cell.cellImageView.clipsToBounds = true
            cell.cellImageView.layer.masksToBounds = true
        }
    }

    // MARK: - UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? EntriesCollectionViewCell else { return }
        if #available(iOS 13.0, *) {
            cell.backgroundColor = UIColor(named: "Theme Colour")
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? EntriesCollectionViewCell else { return }
        if #available(iOS 13.0, *) {
            cell.backgroundColor = UIColor.systemBackground
        } else {
            // Fallback on earlier versions
        }
    }

    
    // Add support for context menus
    @available(iOS 13.0, *)
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let lastIndexPath = IndexPath(row: fetchedResultsController?.fetchedObjects?.count ?? 0, section: 0)
        guard indexPath != lastIndexPath else { return nil }
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
                return self.makeContextMenu(indexPath: indexPath)
            })
        }
        
    @available(iOS 13.0, *)
    func makeContextMenu(indexPath: IndexPath?) -> UIMenu {
            // Create a UIAction for sharing
        let entry = fetchedResultsController?.object(at: indexPath!)
            let newWindow = UIAction(title: "Open in new window", image: UIImage(systemName: "uiwindow.split.2x1")) { action in
                let userActivity = entry?.openDetailUserActivity
                UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil, errorHandler: nil)
            }
            
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil")) { action in
                self.performSegue(withIdentifier: "addEntry", sender: indexPath)
            }
            
            let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { action
                in
                self.shareEntry(indexPath: indexPath!)
            }
            
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.delete(entry: entry!, indexPath: indexPath!)
            }

            if UIDevice.current.userInterfaceIdiom == .pad {
                return UIMenu(title: "", children: [newWindow, edit, share, delete])
            } else {
                return UIMenu(title: "", children: [edit, share, delete])
            } // Don't show new window option if not running on iPad
        }
    
    
    // MARK: - Interface
    func setTitle() {
        self.title = condition?.name
    }
    
    func setInterface() {
        initialiseCoreData()
        setReminderButton()
        setPDFButton()
        self.title = condition?.name
    }
    
    func setReminderButton() {
        guard let reminderSettings = condition?.notificationSettings else { return }
        remindersBarButton.image = reminderSettings.remindersOn ? UIImage(systemName: "bell") : UIImage(systemName: "bell.slash")
        remindersBarButton.isEnabled = true
    }
    
    func setPDFButton() {
        guard let condition = self.condition else { return }
        pdfBarButton.isEnabled = condition.entry!.count > 0 ? true : false
    }
    
    func setEmptyInterface() {
        self.title = "Select or add a condition on the left"
        remindersBarButton.isEnabled = false
        pdfBarButton.isEnabled = false
    }
    
    // Function deselects toolbar items if not enabled.
    func setToolbarEnabled(isDisabled: Bool) {
        #if targetEnvironment(macCatalyst)
        guard let split = splitViewController else { return }
        //split.validateToolbarItem(_ item: NSToolbarItem) -> Bool
        guard let window = self.view.window else { return }
        guard let scene = window.windowScene else { return }
        guard let toolbar = scene.titlebar?.toolbar else { return }
        
        for item in toolbar.items {
            if item.itemIdentifier.rawValue == "reminders" || item.itemIdentifier.rawValue == "pdf" {
            item.isEnabled = !isDisabled
            }
        }
        #endif
    }
    
    func configureForMac(_ animated: Bool) {
        #if targetEnvironment(macCatalyst)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.setToolbarHidden(true, animated: animated)
        #endif
    }
    
    // MARK: - Model
    
    func deleteEntryPhotos(entry: Entry) {
        if let oldImages = entry.image?.allObjects as? [Attachment] {
            for image in oldImages {
                managedObjectContext!.delete(image)
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func sortSegmentedControlChanged(_ sender: Any) {
        /*
        switch sortSegmentedControl.selectedSegmentIndex {
        case 1:
            sortOldest = true
        case 2:
            sortOldest = false
        default:
            break
        } */
    } 
    
    
    func shareEntry(indexPath: IndexPath) {
        let entry = fetchedResultsController!.object(at: indexPath)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: entry.date) + "\n"
        let uiimage = entry.image?.anyObject() as! Attachment
        let image = uiimage.fullImage!.fullImage
        var notes = entry.notes
        if notes != "" {
            notes = "\n" + entry.notes!
        }
        
        let activityView = UIActivityViewController(activityItems: [date, image!, notes!], applicationActivities: nil)
        
        if let popoverPresentationController = activityView.popoverPresentationController {
            popoverPresentationController.sourceView = collectionView.cellForItem(at: indexPath)
        }
        
        self.present(activityView, animated: true, completion: nil)
    }
    
    func delete(entry: Entry, indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete Entry", message: "Deleting an entry is permanent.  Are you sure you would like to continue?", preferredStyle: .actionSheet)
         alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Default action"), style: .destructive, handler: { _ in
            self.managedObjectContext.delete(entry)
            self.updateCoreData()
            self.previousController?.tableView.reloadData()
         }))
         alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
         
        // Block needed to present as popover on iPad - crashes otherwise as Action Sheets unsupported
         if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.sourceView = collectionView.cellForItem(at: indexPath)
         }
        
         self.present(alert, animated: true, completion: nil)
    }
    
    func showReminders() {
        #if targetEnvironment(macCatalyst)
        performSegue(withIdentifier: "showRemindersMac", sender: nil)
        #else
        performSegue(withIdentifier: "showReminders", sender: nil)
        #endif
    }
    
    @objc func generatePDF() {
        guard let condition = self.condition else { print("No Skin Feature in scope");return}
        let rootView = PDFView(vc: self, passedCondition: condition, entriesPerPage: 1, showNotes: true, showDate: true, activitySheetShown: false)
        present(UIHostingController(rootView: rootView), animated: true, completion: nil)
    }
    
    // MARK: - Fetched results controller
    var managedObjectContext: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<Entry>?

    func initialiseCoreData() {
        let request = NSFetchRequest<Entry>(entityName: "Entry")
        let predicate = NSPredicate(format: "condition == %@", condition!)
        let dateSort = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [dateSort]
        request.predicate = predicate
        
        // to group, set sectionNameKeyPath to "dateSection" as specified in Entry class file
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController!.delegate = self
        
        do {
            try fetchedResultsController!.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
   /*
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.updates
    }*/
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: [newIndexPath!])
                self.collectionView.reloadSections(IndexSet.init(integer: 0))
            },completion: {_ in})
        case .delete:
            self.collectionView.deleteItems(at: [indexPath!])
            self.collectionView.reloadSections(IndexSet.init(integer: 0))
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            self.collectionView.performBatchUpdates({
                self.collectionView.moveItem(at: indexPath!, to: newIndexPath!)
                self.collectionView.reloadSections(IndexSet.init(integer: 0))
            },completion: {_ in})
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates(nil, completion: nil)
    }
    
    // MARK: - Core Data
    
    func updateCoreData() {
        do {
            try managedObjectContext!.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
    
    // MARK: - Navigation
    
    
    @IBSegueAction func showPDF(_ coder: NSCoder) -> UIViewController? {
        let rootView = PDFView(vc: self, passedCondition: self.condition, entriesPerPage: 1, showNotes: true, showDate: true)
        return UIHostingController(coder: coder, rootView: rootView)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto" {
            if let indexPath = collectionView.indexPathsForSelectedItems?[0] {
                let controller = segue.destination as! DetailViewController
                controller.managedObjectContext = managedObjectContext
                controller.currentEntry = fetchedResultsController?.fetchedObjects![indexPath.row]
                controller.sortedEntries = fetchedResultsController!.fetchedObjects!
                controller.totalEntries = fetchedResultsController!.fetchedObjects!.count
                controller.currentEntryNumber = indexPath.row
            }
        }
        if segue.identifier == "showReminders" || segue.identifier == "showRemindersMac" {
            let controller = (segue.destination as! UINavigationController).topViewController as! RemindersTableViewController
            controller.previous = self
            controller.passedCondition = self.condition
            controller.managedObjectContext = self.managedObjectContext
        }
        if segue.identifier == "addEntry" {
            let controller = (segue.destination as! UINavigationController).topViewController as! AddEntryTableViewController
            if let indexPath = sender as? IndexPath {
                controller.passedEntry = fetchedResultsController!.object(at: indexPath)
                // if not the initial entry, find the photo of the entry before it
                if indexPath.row > 0 {
                    if let previousEntry = fetchedResultsController?.object(at: IndexPath(row: indexPath.row - 1, section: indexPath.section)) {
                        guard let previousAttachment = previousEntry.image?.anyObject() as? Attachment else { return }
                        controller.previousPhoto = UIImage(data: previousAttachment.fullImage!.fullImage!)
                    }
                }
            } else {
                controller.passedConditionDate? = condition!.startDate!
                if fetchedResultsController!.fetchedObjects!.count > 0 {
                    guard let lastEntryAttachment = fetchedResultsController!.fetchedObjects?.last?.image?.anyObject() as? Attachment else { return }
                    controller.previousPhoto = UIImage(data: lastEntryAttachment.fullImage!.fullImage!)
                }
            }
            
        }
       
    }
    
    @IBAction func unwindFromAddEntry(for unwindSegue: UIStoryboardSegue) {
        guard let addEntryTableViewController = unwindSegue.source as? AddEntryTableViewController else {return}
        let entry: Entry
        var uuid: UUID?
        if addEntryTableViewController.passedEntry != nil {
            entry = addEntryTableViewController.passedEntry!
            uuid = entry.uuid
            deleteEntryPhotos(entry: entry)
        } else {
            entry = Entry(context: managedObjectContext!)
        }
        
        let entryDate = addEntryTableViewController.newEntryDate
        let entryNotes = addEntryTableViewController.newEntryNotes
        
        if uuid == nil {
            uuid = UUID()
            entry.setValue(uuid, forKey: "uuid")
        }
        
        entry.setValue(entryDate, forKey: "date")
        entry.setValue(entryNotes, forKey: "notes")
        
        if let entryImage = addEntryTableViewController.newEntryPhoto {
            let attachment = Attachment(context: managedObjectContext!)
    
            let thumbnail = entryImage.jpegData(compressionQuality: 0.5)
            let id = NSTimeIntervalSince1970
            
            attachment.setValue(thumbnail, forKey: "thumbnail")
            attachment.setValue(id, forKey: "imageID")
            attachment.setValue(entry, forKey: "entry")
            
            let imageData = ImageData(context: managedObjectContext!)
            
            let fullImage = entryImage.jpegData(compressionQuality: 1.0)
            
            imageData.setValue(fullImage, forKey: "fullImage")
            
            
            attachment.setValue(imageData, forKey: "fullImage")
            
            entry.addToImage(attachment)
        }
        
        condition?.addToEntry(entry)
        updateCoreData()
        collectionView.reloadData()
        var feedbackGenerator : UINotificationFeedbackGenerator? = nil
        feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator?.prepare()
        if addEntryTableViewController.newEntryPhoto == nil {
            feedbackGenerator?.notificationOccurred(.warning)
        } else {
            feedbackGenerator?.notificationOccurred(.success)
        }
    }
    
    @IBAction func unwindToConditionEntries(segue: UIStoryboardSegue) {
    }
}

// MARK: - Drag Delegate
extension EntriesCollectionViewController: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let selectedEntry = self.fetchedResultsController!.object(at: indexPath)
        
        let userActivity = selectedEntry.openDetailUserActivity
        
        let itemProvider = NSItemProvider(object: selectedEntry.uuid!.uuidString as NSString)
        itemProvider.registerObject(userActivity, visibility: .all)
        
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = selectedEntry
        
        return [dragItem]
    }
    
    
}
    
// MARK: - Flow Layout
extension EntriesCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 100)
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    
}
