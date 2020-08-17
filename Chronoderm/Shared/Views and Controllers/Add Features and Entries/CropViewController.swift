//
//  CropViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 06/09/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit
import CoreGraphics
import AVKit
import AVFoundation
import PhotosUI
import os

protocol ConfirmPhoto {
    func didConfirmPhoto(image: UIImage)
}

class CropViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Outlets
    
    // Views
    @IBOutlet var originalImageView: UIImageView!
    @IBOutlet var previousImageView: UIImageView!
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var cropView: UIView!
    @IBOutlet var cameraPreview: CameraPreviewView!
    
    // Guides
    @IBOutlet var verticalGuideView: UIView!
    @IBOutlet var horizontalGuideView: UIView!
    
    // Camera Controls
    @IBOutlet var verticalStackView: UIStackView!
    @IBOutlet var horizontalStackView: UIStackView!
    @IBOutlet var flashButton: UIButton!
    @IBOutlet var changeCameraButton: UIButton!
    @IBOutlet var cropButton: UIButton!
    @IBOutlet var overlaySlider: UISlider!
    @IBOutlet var cancelBarButton: UIBarButtonItem!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var retakeButtonEffectView: UIVisualEffectView!
    @IBOutlet var retakeButton: UIButton!
    
    // Constraints
    @IBOutlet var xConstraint: NSLayoutConstraint!
    @IBOutlet var yConstraint: NSLayoutConstraint!
    @IBOutlet var ratioConstraint: NSLayoutConstraint!
    var aspectRatioConstraint: NSLayoutConstraint! = NSLayoutConstraint()
    
    
    // MARK: - Variables
    
    var didConfirmProtocol: ConfirmPhoto?
    
    enum viewState {
        case capture
        case crop
    }
    
    // This variable keeps track whether the view is in capture or crop mode.
    var currentViewState: viewState = .capture
    /*
     didSet {
     print("didSet currentViewState")
     switch currentViewState {
     case .capture:
     // if this is triggered before viewDidLoad, fatalError will occur.
     guard cameraPreview != nil else { return }
     setupCaptureView()
     viewWillAppear(true)
     case .crop:
     guard previousImageView != nil else { return }
     setupCropView()
     }
     }*/
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    var hideCancelButton = false
    
    enum flashMode {
        case auto
        case on
        case off
    }
    
    var preferredFlashMode: flashMode = .auto
    var flashIsSupported: Bool = false
    
    var image: UIImage? {
        didSet {
            print("didSet image")
            guard originalImageView != nil else { return }
            originalImageView.image = image
            /*if image == nil {
             currentViewState = .capture
             } else {
             currentViewState = .crop
             }*/
        }
    }
    var previousImage: UIImage? = nil
    var previousImageFlipped: UIImage? = nil
    var croppedImage: UIImage? {
        cropPhoto()
    }
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // set the current state to capture if there is not a photo passed through.
        currentViewState = image != nil ? .crop : .capture
        cameraPreview.videoPreviewLayer.session = session
        retakeButtonEffectView.layer.cornerRadius = 8.0
        previousImageFlipped = previousImage?.flipped()
        
        switch currentViewState {
        case .capture:
            setupCaptureView()
            // Check to see if authorised
            checkAuthorisation()
            // Set up the video preview view.
            sessionQueue.async {
                self.setupCameraSession()
            }
        case .crop:
            originalImageView.image = image
            setupCropView()
        }
        
        setupOverlayView()
        cancelBarButton.isEnabled = !hideCancelButton
        self.isModalInPresentation = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tryToStartSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.removeObservers()
                self.session.stopRunning()
                self.sessionIsRunning = self.session.isRunning
            }
        }
    }
    
    private var scrollViewSetUp: Bool = false
    
    func setupScrollView() {
        if scrollViewSetUp == false {
            scrollView.delegate = self
            scrollView.maximumZoomScale = 4.0
            scrollView.minimumZoomScale = 1.0
            scrollViewSetUp = true
        }
        scrollView.contentSize = self.originalImageView.frame.size
        
        //Zoom out and centre view
        var centreRect = CGRect()
        
        // Sets the aspect ratio of the imageview to the aspect ratio of the image.
        let newRatioConstraint = NSLayoutConstraint(item: originalImageView!, attribute: .width, relatedBy: .equal, toItem: originalImageView!, attribute: .height, multiplier: image!.size.width / image!.size.height, constant: 0)
        ratioConstraint.isActive = false
        aspectRatioConstraint.isActive = false
        aspectRatioConstraint = newRatioConstraint
        aspectRatioConstraint.isActive = true
        
        // In order to centre the UIImageView in the UIScrollView, if landscape, you must break the x constraint (it will not be in the middle).  If portrait, break the y constraint.  The centre rect also depends on image orientation.
        if image!.size.height > image!.size.width {
            yConstraint.isActive = false
            xConstraint.isActive = true
            centreRect = CGRect(x: 0, y: (originalImageView.frame.height / 2) - (cropView.frame.height), width: cropView.frame.width, height: cropView.frame.height)
        } else {
            xConstraint.isActive = false
            yConstraint.isActive = true
            centreRect = CGRect(x: (originalImageView.frame.width / 2) - (cropView.frame.width / 2), y: 0, width: cropView.frame.width, height: cropView.frame.height)
            print("x: \((originalImageView.frame.width / 2)) - \((cropView.frame.width / 2)), y: \(0), width: \(cropView.frame.width), height \(cropView.frame.height)")
        }
        
        //scrollView.scrollRectToVisible(centreRect, animated: false)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.originalImageView
    }
    
    func setupOverlayView() {
        previousImageView.image = previousImage
        previousImageView.alpha = 0.5
        cropView.layer.borderColor = UIColor(named: "Theme Colour")?.cgColor
        cropView.layer.borderWidth = 5
        verticalGuideView.layer.borderColor = UIColor(named: "Theme Colour 2")?.cgColor
        verticalGuideView.layer.borderWidth = 1
        horizontalGuideView.layer.borderColor = UIColor(named: "Theme Colour 2")?.cgColor
        horizontalGuideView.layer.borderWidth = 1
        /*
         // Setup crop guides
         let bezierPath = UIBezierPath()
         let startPoint = CGPoint(x: cropView.frame.minX + cropView.frame.width / 3, y: cropView.frame.minY)
         let endPoint = CGPoint(x: cropView.frame.minX + cropView.frame.width / 3, y: cropView.frame.maxY)
         bezierPath.move(to: startPoint)
         bezierPath.addLine(to: endPoint)*/
    }
    
    // MARK: - AVFoundation
    enum SetupStatus {
        case authorized
        case success
        case denied
        case restricted
        case configurationFailed
        case unknown
    }
    
    let sessionQueue = DispatchQueue(label: "session queue")
    
    private var setupResult: SetupStatus = .unknown
    let session = AVCaptureSession()
    var photoDeviceInput: AVCaptureDeviceInput!
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                                                                               mediaType: .video, position: .unspecified)
    let photoOutput = AVCapturePhotoOutput()
    
    private var sessionIsRunning: Bool = false
    
    func setupCaptureView() {
        #if targetEnvironment(macCatalyst)
        #else
        self.cameraPreview.isHidden = false
        cropButton.setTitle("Capture", for: .normal)
        cropButton.setImage(UIImage(systemName: "camera"), for: .normal)
        retakeButton.isHidden = true
        let flashControl = horizontalStackView.arrangedSubviews[0]
        let flipControl = horizontalStackView.arrangedSubviews[2]
        flashControl.isHidden = false
        setFlashInterface()
        flipControl.isHidden = false
        let overlayTextAndSlider = verticalStackView.arrangedSubviews[2]
        overlayTextAndSlider.isHidden = previousImage == nil
        #endif
    }
    
    func checkAuthorisation() {
        // Check permissions if not done so already in this session
        guard setupResult == .unknown else { return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            setupResult = .authorized
            break
            
        case .notDetermined: // The user has not yet been asked for camera access.
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .denied
                }
                self.sessionQueue.resume()
            })
            
        case .denied: // The user has previously denied access.
            setupResult = .denied
            return
            
        case .restricted: // The user can't grant access due to restrictions.
            setupResult = .restricted
            return
        default:
            setupResult = .denied
            return
        }
    }
    
    func setupCropView() {
        self.cameraPreview.isHidden = true
        originalImageView.image = image
        updateOverlay(flipped: false)
        setupScrollView()
        cropButton.setTitle("Confirm Crop", for: .normal)
        cropButton.setImage(UIImage(systemName: "crop"), for: .normal)
        retakeButton.isHidden = false
        let flashControl = horizontalStackView.arrangedSubviews[0]
        let flipControl = horizontalStackView.arrangedSubviews[2]
        flashControl.isHidden = true
        flipControl.isHidden = true
        let overlayTextAndSlider = verticalStackView.arrangedSubviews[2]
        overlayTextAndSlider.isHidden = previousImage == nil
    }
    
    func setupCameraSession() {
        guard setupResult == .authorized else { return }
        session.beginConfiguration()
        print("beginConfig")
        session.sessionPreset = .photo
        
        do {
            var defaultDevice: AVCaptureDevice?
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .none, position: .back) {
                defaultDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .none, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .none, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultDevice = frontCameraDevice
            }
            guard let device = defaultDevice else {
                print("Could not add input")
                session.commitConfiguration()
                setupResult = .configurationFailed
                return }
            
            let photoDeviceInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(photoDeviceInput) {
                session.addInput(photoDeviceInput)
                self.photoDeviceInput = photoDeviceInput
                DispatchQueue.main.async {
                    /*
                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                     You can manipulate UIView only on the main thread.
                     Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    self.cameraPreview.videoPreviewLayer.videoGravity = .resizeAspectFill
                    
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if self.windowOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(rawValue: self.windowOrientation.rawValue) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    self.cameraPreview.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
                
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        } else {
            print("Cannot add output")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        setupResult = .success
        if photoDeviceInput.device.hasFlash {
            self.flashIsSupported = true
        } else {
            self.flashIsSupported = false
        }
        session.commitConfiguration()
        DispatchQueue.main.async {
            self.setFlashInterface()
        }
    }
    
    @IBAction func didPressFlashButton(_ sender: Any) {
        changeFlash()
    }
    
    @IBAction func didPressGridButton(_ sender: Any) {
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeInOut, animations: {self.verticalGuideView.isHidden.toggle()
            self.horizontalGuideView.isHidden.toggle()})
        animator.startAnimation()
    }
    
    
    func changeFlash() {
        switch preferredFlashMode {
        case .auto:
            preferredFlashMode = .on
        case .on:
            preferredFlashMode = .off
        case .off:
            preferredFlashMode = .auto
        }
        setFlashInterface()
    }
    
    func setFlashInterface() {
        if flashIsSupported {
            horizontalStackView.arrangedSubviews[0].isHidden = false
            switch preferredFlashMode {
            case .on:
                flashButton.setTitle("On", for: .normal)
                flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
            case .off:
                flashButton.setTitle("Off", for: .normal)
                flashButton.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
            case .auto:
                flashButton.setTitle("Auto", for: .normal)
                flashButton.setImage(UIImage(systemName: "bolt.badge.a.fill"), for: .normal)
            }
        } else {
            horizontalStackView.arrangedSubviews[0].isHidden = true
        }
    }
    
    func updateOverlay(flipped: Bool?) {
        guard setupResult == .success else { return }
        if let flipped = flipped {
            previousImageView.image = flipped ? previousImageFlipped : previousImage
        } else {
            previousImageView.image = photoDeviceInput.device.position == .front ? previousImageFlipped : previousImage
        }
    }
    
    @IBAction func didPressChangeCameraButton(_ sender: Any) {
        flashButton.isEnabled = false
        cropButton.isEnabled = false
        changeCameraButton.isEnabled = false
        
        sessionQueue.async {
            let currentVideoDevice = self.photoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInTrueDepthCamera
                
            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
            }
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            // First, seek a device with both the preferred position and device type. Otherwise, seek a device with only the preferred position.
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, because AVCaptureSession doesn't support
                    // simultaneous use of the rear and front cameras.
                    self.session.removeInput(self.photoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        self.photoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.photoDeviceInput)
                    }
                    
                    
                    
                    /*
                     Set Live Photo capture and depth data delivery if it's supported. When changing cameras, the
                     `livePhotoCaptureEnabled` and `depthDataDeliveryEnabled` properties of the AVCapturePhotoOutput
                     get set to false when a video device is disconnected from the session. After the new video device is
                     added to the session, re-enable them on the AVCapturePhotoOutput, if supported.
                     */
                    self.session.commitConfiguration()
                } catch {
                    print("Error occurred while creating video device input: \(error)")
                }
            }
            if self.photoDeviceInput.device.hasFlash {
                self.flashIsSupported = true
            } else {
                self.flashIsSupported = false
            }
            
            DispatchQueue.main.async {
                self.updateOverlay(flipped: nil)
                self.flashButton.isEnabled = true
                self.setFlashInterface()
                self.cropButton.isEnabled = true
                self.changeCameraButton.isEnabled = true
            }
        }
    }
    
    func tryToStartSession() {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.sessionIsRunning = self.session.isRunning
                DispatchQueue.main.async {
                    self.updateOverlay(flipped: nil)
                }
                
            case .denied:
                DispatchQueue.main.async {
                    let changePrivacyMessage = "Chronoderm doesn't have permission to use the camera.  Please change in Settings app."
                    let alertController = UIAlertController(title: "AVCam", message: changePrivacyMessage, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Chronoderm was unable to configure the camera."
                    let alertController = UIAlertController(title: "Unable to Configure Cameras", message: alertMsg, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            case .restricted:
                DispatchQueue.main.async {
                    let alertMsg = "Restrictions on this device block Chrondoderm from accessing the camera."
                    let alertController = UIAlertController(title: "Camera Restricted", message: alertMsg, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            case .unknown:
                break
            case .authorized:
                break
            }
        }
    }
    
    func capturePhoto() {
        let videoPreviewLayerOrientation = cameraPreview.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            let photoSettings: AVCapturePhotoSettings
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format:
                    [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                photoSettings = AVCapturePhotoSettings()
            }
            if self.photoDeviceInput.device.isFlashAvailable {
                switch self.preferredFlashMode {
                case .auto: photoSettings.flashMode = .auto
                case .on: photoSettings.flashMode = .on
                case .off: photoSettings.flashMode = .off
                }
            } else {
                photoSettings.flashMode = .off
            }
            
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
            
        }
    }
    
    // MARK: - Notifications
    func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: .AVCaptureSessionWasInterrupted,
                                               object: session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded),
                                               name: .AVCaptureSessionInterruptionEnded,
                                               object: session)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func sessionWasInterrupted(notification: NSNotification) {
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            switch reason {
            case .videoDeviceNotAvailableWithMultipleForegroundApps:
                // Fade-in a label to inform the user that the camera is unavailable.
                print("Session stopped running due multitasking.")
                errorLabel.text = "Camera Unavailable in Multitasking Mode"
                errorLabel.alpha = 0
                errorLabel.isHidden = false
                UIView.animate(withDuration: 0.25, animations: {
                    self.errorLabel.alpha = 1
                    self.previousImageView.alpha = 0
                    self.cropButton.isEnabled = false
                }, completion: { _ in
                    self.previousImageView.isHidden = true
                })
            case .videoDeviceNotAvailableDueToSystemPressure:
                print("Session stopped running due to shutdown system pressure level.")
                errorLabel.text = "Camera Unavailable"
                errorLabel.alpha = 0
                errorLabel.isHidden = false
                UIView.animate(withDuration: 0.25, animations: {
                    self.errorLabel.alpha = 1
                    self.previousImageView.alpha = 0
                    self.cameraPreview.alpha = 0
                    self.cropButton.isEnabled = true
                }, completion: { _ in
                    self.previousImageView.isHidden = true
                })
            default:
                print("Session stopped for unknown reason")
            }
        }
    }
    
    @objc func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
        previousImageView.alpha = 0
        previousImageView.isHidden = false
        if !errorLabel.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.errorLabel.alpha = 0
                            self.previousImageView.alpha = CGFloat(self.overlaySlider.value)
            }, completion: { _ in
                self.errorLabel.isHidden = true
            }
            )
        }
    }
    
    // MARK: - Actions
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismissAndSave(image: nil)
    }
    
    @IBAction func addPhotoFromLibrary(_ sender: Any) {
        addPhoto()
    }
    
    func addPhoto() {
        if #available(iOS 14, *) {/*
             var configuration = PHPickerConfiguration()
             configuration.filter = .images
             let picker = PHPickerViewController(configuration: configuration)
             picker.delegate = self
             present(picker, animated: true)*/
        } else {
            let picker = UIImagePickerController()
            picker.allowsEditing = false
            picker.sourceType = .photoLibrary
            picker.delegate = self
            present(picker, animated: true)
        }
    }
    
    @IBAction func retakePhoto(_ sender: Any) {
        currentViewState = .capture
        image = nil
        setupCaptureView()
        checkAuthorisation()
        setupCameraSession()
        tryToStartSession()
    }
    
    
    
    func dismissAndSave(image: UIImage?) {
        if image != nil {
            guard let prot = didConfirmProtocol else { return }
            prot.didConfirmPhoto(image: image!)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirmButtonPressed(_ sender: Any) {
        switch currentViewState {
        case .capture:
            capturePhoto()
        case .crop:
            dismissAndSave(image: cropPhoto())
        }
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = cameraPreview.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
    
    func cropImageToSquare(_ image: UIImage) -> UIImage {
        var rect = CGRect()
        if image.size.width > image.size.height {
            let size = image.size.height
            let minY: CGFloat = 0
            // Find the midpoint of the landscape image's width, and then minus half of the height.
            let minX: CGFloat = (image.size.width / 2) - (size / 2)
            rect = CGRect(x: minX, y: minY, width: size, height: size)
        } else {
            let size = image.size.width
            let minX: CGFloat = 0
            // Find the midpoint of the portrait image's height, and then minus half of the width.
            let minY: CGFloat = (image.size.width / 2) - (size / 2)
            rect = CGRect(x: minX, y: minY, width: size, height: size)
        }
        let cgimage = image.cgImage
        cgimage!.cropping(to: rect)
        return UIImage(cgImage: cgimage!)
    }
    
    
    func cropPhoto() -> UIImage? {
        guard image != nil else { return nil }
        // cropArea is defined as the rect within the UIImage size (most likely to be bigger than the view)
        var cropArea:CGRect
        
        // scale = the amount the UIScrollView is enlarged
        let zoomScale = 1/scrollView.zoomScale
        print("zoomScale = \(zoomScale)")
        
        // photoScale = how much the image size is greater than the imageView.  This should be calculated using the shortest side, as its bounds equals the cropView frame.
        let photoScale = image!.size.height > image!.size.width ? originalImageView.image!.size.width / scrollView.frame.width : originalImageView.image!.size.height / cropView.frame.height
        print("photoScale = \(photoScale)")
        print("\(originalImageView.image!.size.height) \(cropView.frame.width)")
        
        let imageOrientation = image!.imageOrientation
        let imageScale = image!.scale
        print(imageOrientation.rawValue)
        
        // photoFrame = photo within image view aspect fit
        let photoFrame = getImageFrame(forImage: image!, inImageView: originalImageView)
        
        let cropX = (scrollView.contentOffset.x - photoFrame.origin.x) * zoomScale * photoScale * imageScale
        let cropY = (scrollView.contentOffset.y - photoFrame.origin.y) * zoomScale * photoScale * imageScale
        let cropWidth = cropView.frame.width * photoScale * zoomScale * imageScale
        let cropHeight = cropView.frame.height * photoScale * zoomScale * imageScale
        cropArea = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        
        print("imageSize = \(image!.size)")
        print("cropX = (\(scrollView.contentOffset.x) - \(photoFrame.origin.x)) * \(zoomScale) * \(photoScale) * \(imageScale) = \(cropX)")
        print("cropY = (\(scrollView.contentOffset.y) - \(photoFrame.origin.y)) * \(zoomScale) * \(photoScale) = \(cropY)")
        print("cropWidth = \(cropView.frame.width) * \(photoScale) * \(zoomScale) = \(cropWidth)")
        print("cropHeight = \(cropView.frame.height) * \(photoScale) * \(zoomScale) = \(cropHeight)")
        /*
        switch imageOrientation {
        case .up:
            let cropX = (scrollView.contentOffset.x - photoFrame.origin.x) * zoomScale * photoScale * imageScale
            let cropY = (scrollView.contentOffset.y - photoFrame.origin.y) * zoomScale * photoScale * imageScale
            let cropWidth = cropView.frame.width * photoScale * zoomScale * imageScale
            let cropHeight = cropView.frame.height * photoScale * zoomScale * imageScale
            cropArea = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
            
            print("imageSize = \(image!.size)")
            print("cropX = (\(scrollView.contentOffset.x) - \(photoFrame.origin.x)) * \(zoomScale) * \(photoScale) * \(imageScale) = \(cropX)")
            print("cropY = (\(scrollView.contentOffset.y) - \(photoFrame.origin.y)) * \(zoomScale) * \(photoScale) = \(cropY)")
            print("cropWidth = \(cropView.frame.width) * \(photoScale) * \(zoomScale) = \(cropWidth)")
            print("cropHeight = \(cropView.frame.height) * \(photoScale) * \(zoomScale) = \(cropHeight)")
        case .down:
            let cropX = (scrollView.contentOffset.x - photoFrame.origin.x) * zoomScale * photoScale * imageScale
            let cropY = (scrollView.contentOffset.y - photoFrame.origin.y) * zoomScale * photoScale * imageScale
            let cropWidth = cropView.frame.width * photoScale * zoomScale * imageScale
            let cropHeight = cropView.frame.height * photoScale * zoomScale * imageScale
            cropArea = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
            
            print("imageSize = \(image!.size)")
            print("cropX = (\(scrollView.contentOffset.x) - \(photoFrame.origin.x)) * \(zoomScale) * \(photoScale) * \(imageScale) = \(cropX)")
            print("cropY = (\(scrollView.contentOffset.y) - \(photoFrame.origin.y)) * \(zoomScale) * \(photoScale) = \(cropY)")
            print("cropWidth = \(cropView.frame.width) * \(photoScale) * \(zoomScale) = \(cropWidth)")
            print("cropHeight = \(cropView.frame.height) * \(photoScale) * \(zoomScale) = \(cropHeight)")
        case .left:
            let cropY = (scrollView.contentOffset.x - photoFrame.origin.x) * zoomScale * photoScale * imageScale
            let cropX = (scrollView.contentOffset.y - photoFrame.origin.y) * zoomScale * photoScale * imageScale
            let cropWidth = cropView.frame.width * photoScale * zoomScale * imageScale
            let cropHeight = cropView.frame.height * photoScale * zoomScale * imageScale
            cropArea = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
            
            print("imageSize = \(image!.size)")
            print("cropX = (\(scrollView.contentOffset.x) - \(photoFrame.origin.x)) * \(zoomScale) * \(photoScale) * \(imageScale) = \(cropX)")
            print("cropY = (\(scrollView.contentOffset.y) - \(photoFrame.origin.y)) * \(zoomScale) * \(photoScale) = \(cropY)")
            print("cropWidth = \(cropView.frame.width) * \(photoScale) * \(zoomScale) = \(cropWidth)")
            print("cropHeight = \(cropView.frame.height) * \(photoScale) * \(zoomScale) = \(cropHeight)")
        case .right:
            let cropY = (scrollView.contentOffset.x - photoFrame.origin.x) * zoomScale * photoScale * imageScale
            let cropX = (scrollView.contentOffset.y - photoFrame.origin.y) * zoomScale * photoScale * imageScale
            let cropWidth = cropView.frame.width * photoScale * zoomScale * imageScale
            let cropHeight = cropView.frame.height * photoScale * zoomScale * imageScale
            cropArea = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
            
            print("imageSize = \(image!.size)")
            print("cropX = (\(scrollView.contentOffset.x) - \(photoFrame.origin.x)) * \(zoomScale) * \(photoScale) * \(imageScale) = \(cropX)")
            print("cropY = (\(scrollView.contentOffset.y) - \(photoFrame.origin.y)) * \(zoomScale) * \(photoScale) = \(cropY)")
            print("cropWidth = \(cropView.frame.width) * \(photoScale) * \(zoomScale) = \(cropWidth)")
            print("cropHeight = \(cropView.frame.height) * \(photoScale) * \(zoomScale) = \(cropHeight)")
        default:
            let cropX = (scrollView.contentOffset.x - photoFrame.origin.x) * zoomScale * photoScale * imageScale
            let cropY = (scrollView.contentOffset.y - photoFrame.origin.y) * zoomScale * photoScale * imageScale
            let cropWidth = cropView.frame.width * photoScale * zoomScale * imageScale
            let cropHeight = cropView.frame.height * photoScale * zoomScale * imageScale
            cropArea = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
            
            print("imageSize = \(image!.size)")
            print("cropX = (\(scrollView.contentOffset.x) - \(photoFrame.origin.x)) * \(zoomScale) * \(photoScale) * \(imageScale) = \(cropX)")
            print("cropY = (\(scrollView.contentOffset.y) - \(photoFrame.origin.y)) * \(zoomScale) * \(photoScale) = \(cropY)")
            print("cropWidth = \(cropView.frame.width) * \(photoScale) * \(zoomScale) = \(cropWidth)")
            print("cropHeight = \(cropView.frame.height) * \(photoScale) * \(zoomScale) = \(cropHeight)")
        }*/
        
        let CGImage = image!.cgImage
        let croppedCGImage = CGImage!.cropping(to: cropArea)
        //return UIImage(cgImage: croppedCGImage!, scale: imageScale, orientation: imageOrientation)
        return image!.croppedImage(inRect: cropArea)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        previousImageView.alpha = CGFloat(overlaySlider.value)
    }
    
    func getImageFrame(forImage image: UIImage, inImageView imageView: UIImageView) -> CGRect {
        return AVMakeRect(aspectRatio: image.size, insideRect: imageView.frame)
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension CropViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            guard let photoData = photo.fileDataRepresentation() else { return }
            print("Photo taken")
            sessionQueue.async {
                self.session.stopRunning()
            }
            let uncroppedImage = UIImage(data: photoData)
            //self.image = cropImageToSquare(uncroppedImage!)
            self.image = uncroppedImage!
            self.currentViewState = .crop
            setupCropView()
            
        }
    }
}

// MARK: - Photo Picker
extension CropViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        sessionQueue.async {
            self.session.stopRunning()
        }
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        self.image = image
        self.currentViewState = .crop
        self.setupCropView()
    }
}

/*
 @available(iOS 14, *)
 extension CropViewController: PHPickerViewControllerDelegate {
 
 func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
 // The client is responsible for presentation and dismissal
 picker.dismiss(animated: true)
 sessionQueue.async {
 self.session.stopRunning()
 }
 
 // Get the first item provider from the results, the configuration only allowed one image to be selected
 let itemProvider = results.first?.itemProvider
 
 if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
 itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
 DispatchQueue.main.async {
 guard let image = image as? UIImage else { return }
 self.image = image
 }
 }
 } else {
 // TODO: Handle empty results or item provider not being able load UIImage
 }
 }
 
 }*/
