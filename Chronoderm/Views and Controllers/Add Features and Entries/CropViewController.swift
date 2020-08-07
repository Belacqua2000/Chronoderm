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

protocol ConfirmPhoto {
    func didConfirmPhoto(image: UIImage)
}

class CropViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet var originalImageView: UIImageView!
    @IBOutlet var previousImageView: UIImageView!
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var cropView: UIView!
    @IBOutlet var verticalGuideView: UIView!
    @IBOutlet var horizontalGuideView: UIView!
    
    
    @IBOutlet var verticalStackView: UIStackView!
    @IBOutlet var flashButton: UIButton!
    @IBOutlet var changeCameraButton: UIButton!
    @IBOutlet var cropButton: UIButton!
    @IBOutlet var overlaySlider: UISlider!
    @IBOutlet var cancelBarButton: UIBarButtonItem!
    @IBOutlet var retakeButton: UIButton!
    
    @IBOutlet var xConstraint: NSLayoutConstraint!
    @IBOutlet var yConstraint: NSLayoutConstraint!
    @IBOutlet var ratioConstraint: NSLayoutConstraint!
    
    @IBOutlet var cameraPreview: CameraPreviewView!
    
    // MARK: - Variables
    
    var didConfirmProtocol: ConfirmPhoto?
    
    enum viewState {
        case capture
        case crop
    }
    
    // This variable keeps track whether the view is in capture or crop mode.
    var currentViewState: viewState = .capture {
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
        }
    }
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    var hideCancelButton = false
    
    enum flashMode {
        case auto
        case on
        case off
    }
    
    var currentFlashMode: flashMode = .auto
    
    var image: UIImage? {
        didSet {
            print("didSet image")
            guard originalImageView != nil else { return }
            originalImageView.image = image
            if image == nil {
                currentViewState = .capture
            } else {
                currentViewState = .crop
            }
        }
    }
    var previousImage: UIImage? = nil
    var croppedImage: UIImage? {
        cropPhoto()
    }

    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // set the current state to capture if there is not a photo passed through.
        currentViewState = image != nil ? .crop : .capture
        
        switch currentViewState {
        case .capture:
            setupCaptureView()
            setFlashInterface()
        case .crop:
            originalImageView.image = image
            setupCropView()
        }
        
        setupOverlayView()
        cancelBarButton.isEnabled = !hideCancelButton
        self.isModalInPresentation = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        sessionQueue.async {
            self.session.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            self.session.stopRunning()
        }
    }
    
    func setupScrollView() {
        scrollView.delegate = self
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 1.0
        scrollView.contentSize = self.originalImageView.frame.size
        
        // In order to centre the imageview, if landscape, you must break the x constraint (it will not be in the middle).  If portrait, break the y constraint.
        if image!.size.height > image!.size.width {
            yConstraint.isActive = false
        } else {
            xConstraint.isActive = false
        }
        
        // Sets the aspect ratio of the imageview to the aspect ratio of the image.
        let newRatioConstraint = NSLayoutConstraint(item: originalImageView!, attribute: .width, relatedBy: .equal, toItem: originalImageView!, attribute: .height, multiplier: image!.size.width / image!.size.height, constant: 0)
        ratioConstraint.isActive = false
        newRatioConstraint.isActive = true
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
    enum authorisationStatus {
        case authorized
        case denied
        case restricted
        case unknown
    }
    
    let sessionQueue = DispatchQueue(label: "session queue")
    
    var status: authorisationStatus = .unknown
    let session = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput!
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                                                                               mediaType: .video, position: .unspecified)
    let photoOutput = AVCapturePhotoOutput()
    
    var sessionIsRunning: Bool = false
    
    func checkAuthorisation() {
        // Check permissions
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                status = .authorized
                //self.setupCaptureSession()
            
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.status = .authorized
                        //self.setupCaptureSession()
                    }
                }
            
            case .denied: // The user has previously denied access.
                status = .denied
                return

            case .restricted: // The user can't grant access due to restrictions.
                status = .restricted
                return
        @unknown default:
            return
        }
    }
    
    func setupCameraSession() {
        guard status == .authorized else { return }
        session.beginConfiguration()
        print("beginConfig")
        
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .none, position: .unspecified)
        guard let input = try? AVCaptureDeviceInput(device: device!),session.canAddInput(input) else {
            print("Could not add input")
            session.commitConfiguration()
            return }
        session.addInput(input)
        self.videoDeviceInput = input
        
        guard session.canAddOutput(photoOutput) else {
            print("Cannot add output")
            session.commitConfiguration()
            return }
        session.sessionPreset = .photo
        session.addOutput(photoOutput)
        session.commitConfiguration()
        print("commitConfig")
        
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
    }
    
    @IBAction func didPressFlashButton(_ sender: Any) {
        changeFlash()
    }
    
    func changeFlash() {
        switch currentFlashMode {
        case .auto:
            currentFlashMode = .on
        case .on:
            currentFlashMode = .off
        case .off:
            currentFlashMode = .auto
        }
        setFlashInterface()
    }
    
    func setFlashInterface() {
        switch currentFlashMode {
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
    }
    
    @IBAction func didPressChangeCameraButton(_ sender: Any) {
        flashButton.isEnabled = false
        cropButton.isEnabled = false
        changeCameraButton.isEnabled = false
        
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
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
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
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
            
            DispatchQueue.main.async {
                if self.videoDeviceInput.device.position == .front {
                    print("front")
                }
                self.flashButton.isEnabled = true
                self.cropButton.isEnabled = true
                self.changeCameraButton.isEnabled = true
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
            switch self.currentFlashMode {
            case .auto: photoSettings.flashMode = .auto
            case .on: photoSettings.flashMode = .on
            case .off: photoSettings.flashMode = .off
            }
            
            /* let delegate = PhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: {}, completionHandler: { processor in
                DispatchQueue.main.async {
                    let data = processor.photoData!
                    self.image = UIImage(data: data)
                    self.currentViewState = .crop
                    self.setupScrollView()
                }
            }, photoProcessingHandler: {_ in })
            */
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
            
        }
        /*
        let imageData = delegate.photoData!
        let image = UIImage(data: imageData)
        self.image = image
        setupScrollView() */
    }
    
    // MARK: - Actions
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismissAndSave(image: nil)
    }
    
    @IBAction func addPhotoFromLibrary(_ sender: Any) {
        addPhoto()
    }
    
    func addPhoto() {
        if #available(iOS 14, *) {
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.allowsEditing = false
            picker.sourceType = .photoLibrary
            picker.delegate = self
            present(picker, animated: true)
        }
    }
    
    @IBAction func retakePhoto(_ sender: Any) {
        image = nil
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
    
    func setupCaptureView() {
        #if targetEnvironment(macCatalyst)
        #else
        // Set up the video preview view.
        self.cameraPreview.videoPreviewLayer.session = self.session
        cropButton.setTitle("Capture", for: .normal)
        cropButton.setImage(UIImage(systemName: "camera"), for: .normal)
        retakeButton.isHidden = true
        let cameraControls = verticalStackView.arrangedSubviews[1]
        cameraControls.isHidden = false
        let overlayText = verticalStackView.arrangedSubviews[2]
        let overlaySlider = verticalStackView.arrangedSubviews[3]
        overlayText.isHidden = previousImage == nil
        overlaySlider.isHidden = previousImage == nil
        checkAuthorisation()
        sessionQueue.async {
            self.setupCameraSession()
        }
        #endif
    }
    
    func setupCropView() {
        self.cameraPreview.isHidden = true
        originalImageView.image = image
        setupScrollView()
        cropButton.setTitle("Confirm Crop", for: .normal)
        cropButton.setImage(UIImage(systemName: "crop"), for: .normal)
        retakeButton.isHidden = false
        let cameraControls = verticalStackView.arrangedSubviews[1]
        cameraControls.isHidden = true
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
        }
       
        let CGImage = image!.cgImage
        let croppedCGImage = CGImage!.cropping(to: cropArea)
        return UIImage(cgImage: croppedCGImage!, scale: imageScale, orientation: imageOrientation)
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
                self.session.commitConfiguration()
                self.session.stopRunning()
            }
            let uncroppedImage = UIImage(data: photoData)
            //self.image = cropImageToSquare(uncroppedImage!)
            self.image = uncroppedImage!
            setupCropView()
            
        }
    }
}

// MARK: - Photo Picker
extension CropViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        self.image = image
    }
}


@available(iOS 14, *)
extension CropViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // The client is responsible for presentation and dismissal
        picker.dismiss(animated: true)
        
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
    
}
