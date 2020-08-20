//
//  AddEntryTableViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 16/07/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

class AddEntryTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDropInteractionDelegate, ConfirmPhoto {
    
    // MARK: - Outlets
    
    @IBOutlet var entryDateLabel: UILabel!
    
    @IBOutlet var entryDatePicker: UIDatePicker!
    
    @IBOutlet var entryImageView: UIImageView!
    
    @IBOutlet var entryNotesField: UITextView!
    
    @IBOutlet var saveBarButton: UIBarButtonItem!
    
    @IBOutlet var overlayView: UIView?
    
    @IBOutlet var overlayImage: UIImageView?
    
    @IBOutlet var overlayTextView: UIVisualEffectView!
    
    @IBOutlet var addPhotoLabel: UILabel!
    
    let entryDateLabelIndexPath = IndexPath(row: 0, section: 1)
    let entryDatePickerIndexPath = IndexPath(row: 1, section: 1)
    let addPhotoIndexPath = IndexPath(row: 0, section: 0)
    let entryImageViewIndexPath = IndexPath(row: 1, section: 0)
    let entryNotesFieldIndexPath = IndexPath(row: 0, section: 2)
    
    var entryDatePickerShown: Bool = false {
        didSet {
            entryDatePicker.isHidden = !entryDatePickerShown
        }
    }
    
    let defaults = UserDefaults.standard
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if passedEntry != nil {
            isInAddView = false
            configureEditView()
        }
        updateSaveButton()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        entryDatePicker.maximumDate = Date()
        entryDatePicker.minimumDate = passedConditionDate
        updateDates()
        
        let dropInteraction = UIDropInteraction(delegate: self)
        entryImageView.addInteraction(dropInteraction)
        
    }
    
    var isInAddView = true
    
    func configureEditView() {
        passedConditionDate = passedEntry?.condition.startDate
        entryDatePicker.date = passedEntry!.date
        updateDates()
        if let entryImage = passedEntry?.image?.anyObject() as? Attachment {
            entryImageView.image = UIImage(data: entryImage.fullImage!.fullImage!)
        }
        entryNotesField.text = passedEntry?.notes
        addPhotoLabel.text = "Edit"
    }
    
    func updateSaveButton() {
        saveBarButton.isEnabled = self.entryImageView.image != nil
    }
    
    // MARK: - Table View Source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return entryImageView.image == nil ? 1 : 2
        case 1: return entryDatePickerShown ? 2 : 1
        case 2: return 1
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        // Hides DatePicker when tapping on cell above (like calendar)
        case entryDatePickerIndexPath:
            if entryDatePickerShown {
                return 216.0
            } else {
                return 0.0
            }
        // Make ImageView and Notes Field cells larger
        case entryImageViewIndexPath:
            return 256.0
        case entryNotesFieldIndexPath:
            return 256.0
        default:
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath {
        case entryDateLabelIndexPath:
            entryDatePickerShown.toggle()
            tableView.beginUpdates()
            if entryDatePickerShown == true {
                tableView.insertRows(at: [entryDatePickerIndexPath], with: .automatic)
            } else {
                tableView.deleteRows(at: [entryDatePickerIndexPath], with: .automatic)
            }
            tableView.endUpdates()
        case addPhotoIndexPath:
            addPhoto(self)
        default:
            break
        }
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    // MARK: - Model
    
    var passedEntry: Entry?
    
    var passedConditionDate: Date?
    
    var previousPhoto: UIImage?
    
    var newEntryDate: Date? {
        let date = entryDatePicker.date
        
        return date
    }
    
    var newEntryNotes: String? {
        let notes = entryNotesField.text
        
        return notes
    }
    
    var newEntryPhoto: UIImage? {
        let image = entryImageView.image
        
        return image
    }
    
    // MARK: - Drag & Drop
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let dropLocation = session.location(in: view)
       // updateLayers(forDropLocation: dropLocation)

        let operation: UIDropOperation

        if entryImageView.frame.contains(dropLocation) {
            /*
                 If you add in-app drag-and-drop support for the .move operation,
                 you must write code to coordinate between the drag interaction
                 delegate and the drop interaction delegate.
            */
            operation = session.localDragSession == nil ? .copy : .move
        } else {
            // Do not allow dropping outside of the image view.
            operation = .cancel
        }

        return UIDropProposal(operation: operation)
    }
 

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        // Consume drag items (in this example, of type UIImage).
        session.loadObjects(ofClass: UIImage.self) { imageItems in
            let images = imageItems as! [UIImage]

            /*
                 If you do not employ the loadObjects(ofClass:completion:) convenience
                 method of the UIDropSession class, which automatically employs
                 the main thread, explicitly dispatch UI work to the main thread.
                 For example, you can use `DispatchQueue.main.async` method.
            */
            self.entryImageView.image = images.first
            self.performSegue(withIdentifier: "crop", sender: "Drop")
        }
        // Enable save bar button when dragging in a photo
        updateSaveButton()
        
    }
    
    // MARK: - Configure Overlay
    func configureOverlay() {
        overlayTextView.layer.cornerRadius = 10
        overlayTextView.clipsToBounds = true
        guard defaults.bool(forKey: "CameraOverlayIsShown") == true else { return }
        if let overlayImage = previousPhoto {
            self.overlayImage?.image = overlayImage
            self.overlayImage?.alpha = 0.5
        }
    }
    
    // MARK: - Actions
    
    @IBAction func datePickerChanged(_ sender: Any) {
        updateDates()
    }
    
    // MARK: - Camera
    @IBAction func addPhoto(_ sender: Any) {
        
        return
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        let alertController = UIAlertController(title: "Choose image source", message: nil, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            
            let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { action in
                imagePicker.sourceType = .camera
                // Apply our overlay view containing the toolar to take pictures in various ways.
                self.configureOverlay()
                self.overlayView?.frame = (imagePicker.cameraOverlayView?.frame)!
                imagePicker.cameraOverlayView = self.overlayView
                print(UIScreen.main.bounds.height)
                switch UIScreen.main.bounds.height {
                case 568: imagePicker.cameraViewTransform = imagePicker.cameraViewTransform.translatedBy(x: 0, y: 30)
                case 667: imagePicker.cameraViewTransform = imagePicker.cameraViewTransform.translatedBy(x: 0, y: 40)
                case 896: imagePicker.cameraViewTransform = imagePicker.cameraViewTransform.translatedBy(x: 0, y: 50)
                default: break
                }
                imagePicker.cameraOverlayView?.isUserInteractionEnabled = false
                self.present(imagePicker, animated: true, completion: nil)
            })
            alertController.addAction(cameraAction)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let photoAction = UIAlertAction(title: "Photo Library", style: .default, handler: { action in
                imagePicker.sourceType = .photoLibrary
                self.configureOverlay()
                if let popoverPresentationController = imagePicker.popoverPresentationController {
                    popoverPresentationController.sourceView = self.tableView.cellForRow(at: self.addPhotoIndexPath)?.contentView
                }
                self.present(imagePicker, animated: true, completion: nil)
            })
            alertController.addAction(photoAction)
        }
        
        present(alertController, animated: true, completion: nil)
        /*
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "_UIImagePickerControllerUserDidCaptureItem"), object:nil, queue:nil, using: { note in
            self.overlayView?.alpha = 0.2
            imagePicker.cameraOverlayView?.isUserInteractionEnabled = false
           })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "_UIImagePickerControllerUserDidRejectItem"), object:nil, queue:nil, using: { note in
         self.overlayView?.alpha = 1
        })*/
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.editedImage] as? UIImage else {return}
        
        // Save the photo to the Photo library if the setting is enabled in app settings
        if picker.sourceType == .camera {
            if defaults.bool(forKey: "saveImageToPhotos") == true {
                UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
            } // Save photo to camera roll if set in Settings
        }
        
        entryImageView.image = selectedImage
        
        updateSaveButton()
        addPhotoLabel.text = "Edit"
        dismiss(animated: true, completion: nil)
        tableView.reloadData()
        performSegue(withIdentifier: "crop", sender: "UIImagePickerController")
    }
    
    func didConfirmPhoto(image: UIImage) {
        entryImageView.image = image
        updateSaveButton()
        addPhotoLabel.text = "Edit"
        tableView.reloadData()
    }
    
    // Updates the cell above the date picker with the date chosen
    func updateDates() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        entryDateLabel.text = dateFormatter.string(from: entryDatePicker.date)
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "crop" {
            let controller = (segue.destination as! UINavigationController).viewControllers.first as! CropViewController
            controller.image = self.entryImageView.image
            controller.previousImage = previousPhoto
            controller.didConfirmProtocol = self
            if sender as? String == "UIImagePickerController" || sender as? String == "Drop" {
                controller.hideCancelButton = true
            }
        }
    }
    
    @IBAction func unwindFromCrop(for unwindSegue: UIStoryboardSegue) {
        guard let sourceViewController = unwindSegue.source as? CropViewController else { return }
        // Use data from the view controller which initiated the unwind segue
        self.entryImageView.image = sourceViewController.croppedImage
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    
}
