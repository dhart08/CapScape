//
//  ViewController.swift
//  CapScape
//
//  Created by David on 9/7/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import GPUImage
import MapKit
import SwiftyDropbox

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {

// MARK: - Object References --------------------------------------------------
    
    @IBOutlet weak var cameraView: CameraView!
    @IBOutlet weak var mapView: MapView!
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var slideshowButton: CustomButton!
    @IBOutlet weak var toolsButton: UIButton!
    @IBOutlet weak var zoomLabel: UILabel!
    @IBOutlet weak var filenameLabel: UILabel!
    
    @IBOutlet weak var switchesContainer: UIView!
    @IBOutlet weak var gpsSwitch: UISwitch!
    @IBOutlet weak var indexSwitch: UISwitch!
    
    
    @IBOutlet weak var splashScreenContainer: UIView!
    @IBOutlet weak var landscapeImage: UIImageView!
    @IBOutlet weak var appNameImage: UIImageView!
    
// MARK: - APP Variables ------------------------------------------------------
    
    var locationManager: CLLocationManager!
    var locationFinder: LocationFinder!
    
    var angleReader: AngleReader!
    
    var directoryHandler: DirectoryHandler!
    
    //var dropboxClient: DropboxClient! = nil
    var dropboxUploader: DropboxUploader!
    
    var camera: Camera!
    var movieInput: MovieInput!
    var movieOutput: MovieOutput!
    var renderView: RenderView!
    var cameraOverlayBlendFilter: SourceOverBlend!
    //var cameraBlender: SourceOverBlend!
    //var overlayBlender: SourceOverBlend!
    var chromaFilter: ChromaKeying!
    var coordinatesOverlay: PictureInput!
    var pictureOutput: PictureOutput!
    var imageOrientation: UIImageOrientation! = UIImageOrientation.up
    var videoOrientation: CGFloat!
    var lastPictureImage: UIImage!
    var audioRecorder: AVAudioRecorder!
    var currentSlideshowInput: PictureInput!
    var slideShowBlendFilter: SourceOverBlend!
    var slideshowMovieOutput: MovieOutput!
    
    var videoRecordingOrientation: UIImageOrientation = UIImageOrientation.up
    var isVideoRecording: Bool = false
    var isAudioRecording: Bool = false
    var fileURL: URL!
    
    var isMapFullScreen: Bool = false
    var mapViewFrame: CGRect!
    var closeMapButton: UIButton!
    
    var lastZoomFactor: CGFloat = 1.0
    
    var userSettingsModel: UserSettingsModel = UserSettingsModel()
    var fileCount: Int = 0
    var fileCountFormat = "%03d"
    var fileCountIndex = 0
    var fileCountIndexIsLocked = false
    
    var updateCoordinates: Bool = true
    var currentLatitudeString: String = ""
    var currentLongitudeString: String = ""
    var currentLatitudeDouble: Double = 0
    var currentLongitudeDouble: Double = 0

// MARK: - ViewController Methods ---------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // made quickly for kristen, can delete
//        let licenseValidator = LicenseValidator()
//        if licenseValidator.isCurrentLicenseValid() == false {
//            print("expired license in viewDidLoad()!!!")
//
//            let alert = UIAlertController(title: "Expired", message: "Your license has expired. Please contact technical support.", preferredStyle: .alert)
//            present(alert, animated: true, completion: nil)
//        }
        
        animateSplashScreen()
        
//        let licenseValidator = LicenseValidator()
//        if licenseValidator.isCurrentLicenseValid() == false {
//            print("Current License: invalid")
//
//            //disable app use
//            //view.isHidden = true //makes alert below laggy
//            let blurEffect = UIBlurEffect(style: .regular)
//            let blurView = UIVisualEffectView(effect: blurEffect)
//            blurView.frame = self.view.frame
//            self.view.addSubview(blurView)
//
//            func askUserLicenseBlock() {
//                DispatchQueue.main.async {
//                    licenseValidator.askUserForLicense(controller: self, message: "Enter serial and key:", completion: { (serial, key) in
//
//                        let newLicense = licenseValidator.convertUserInputToLicense(serial: serial, key: key)
//                        if newLicense != nil {
//                            print("New License: ", newLicense!)
//
//                            //check if new license is valid
//                            if licenseValidator.isNewLicenseValid(newLicense: newLicense!) == true {
//                                print("New License is valid!")
//
//                                self.userSettingsModel.setExpirationDate(date: newLicense!)
//                                blurView.removeFromSuperview()
//                            }
//                            else {
//                                print("New License is not valid!")
//
//                                //restart user input process
//                                askUserLicenseBlock()
//                            }
//                        }
//                        else {
//                            print("Could not convert input to valid license!")
//
//                            //restart user input process
//                            askUserLicenseBlock()
//                        }
//                    })
//                }
//            }
//
//            askUserLicenseBlock()
//        }
        
        //NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveCoordinates(_:)), name: .didReceiveCoordinates, object: nil)
        
        locationFinder = LocationFinder()
        locationFinder.locationUpdateCallbacks.append {
            self.locationChange()
        }
        locationFinder.headingUpdateCallbacks.append {
            self.locationChange()
        }
        locationFinder.requestAuthorization()
        
        angleReader = AngleReader()

        
        directoryHandler = DirectoryHandler()
        directoryHandler.changeDirectory(dirType: .appDocuments, url: nil)
        
        setFilenameLabelText()
        updateCoordinatesOverlay(latitude: "Waiting...", longitude: "Waiting...", cardinalDirection: "NA")
        
//        DispatchQueue.global().async {
        
            setCameraDevice()

            renderView = RenderView(frame: cameraView.bounds)
            renderView.fillMode = .stretch
            cameraView.addSubview(renderView)
            cameraView.bringSubview(toFront: filenameLabel)
            //cameraView.bringSubview(toFront: zoomLabel)
            cameraView.bringSubview(toFront: switchesContainer)

            cameraOverlayBlendFilter = SourceOverBlend()
            chromaFilter = ChromaKeying()
            chromaFilter.colorToReplace = Color.green

            camera --> cameraOverlayBlendFilter
            coordinatesOverlay --> chromaFilter --> cameraOverlayBlendFilter --> renderView

            coordinatesOverlay.processImage()
            camera.startCapture()
        
//            self.setCameraDevice()
//
//            self.renderView = RenderView(frame: self.cameraView.bounds)
//            self.renderView.fillMode = .stretch
//            self.cameraView.addSubview(self.renderView)
//            self.cameraView.bringSubview(toFront: self.filenameLabel)
//            self.cameraView.bringSubview(toFront: self.zoomLabel)
//
//            self.cameraOverlayBlendFilter = SourceOverBlend()
//            self.chromaFilter = ChromaKeying()
//            self.chromaFilter.colorToReplace = Color.green
//
//            self.camera --> self.cameraOverlayBlendFilter
//            self.coordinatesOverlay --> self.chromaFilter --> self.cameraOverlayBlendFilter --> self.renderView
//
//            self.coordinatesOverlay.processImage()
//            self.camera.startCapture()
//
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("ViewController: viewWillAppear")
        NotificationCenter.default.addObserver(self, selector: #selector(onDeviceRotation), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        locationFinder.startFindingLocation()
        camera.startCapture()
        onDeviceRotation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        locationFinder.stopFindingLocation()
        camera.stopCapture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
// MARK: - Element Click Actions ------------------------------------------------
    
    @IBAction func videoButtonClick(_ sender: UIButton) {
        if isVideoRecording == false {
            isVideoRecording = true
            videoRecordingOrientation = imageOrientation
            
            sender.setImage(UIImage(named: "video_stop"), for: .normal)
            slideshowButton.setImage(UIImage(named: "slideshow_disabled"), for: .normal)
            slideshowButton.isEnabled = false
            photoButton.setImage(UIImage(named: "photo_disabled"), for: .normal)
            photoButton.isEnabled = false
            toolsButton.setImage(UIImage(named: "toolbox_disabled"), for: .normal)
            toolsButton.isEnabled = false
            
            
            directoryHandler.createDirectory(dirType: .videos)
            
            fileURL = URL(string: "Videos/\(createTimestamp()).mp4", relativeTo: directoryHandler.getDocumentsPath())
            
            do {
                try FileManager.default.removeItem(at: fileURL!)
            }
            catch {
                
            }
            
            DispatchQueue.global().async {
            
            self.movieOutput = try!  MovieOutput(URL: self.fileURL!, size: Size(width: 1080, height: 1920), liveVideo: true)
            
            //self.blendFilter --> self.movieOutput
            self.cameraOverlayBlendFilter --> self.movieOutput
            
            self.camera.audioEncodingTarget = self.movieOutput
            
            //self.movieOutput.startRecording()
            self.movieOutput.startRecording(transform: CGAffineTransform(rotationAngle: self.videoOrientation))
            }
        }
        else {
            isVideoRecording = false
            
            movieOutput.finishRecording() {
                self.camera.audioEncodingTarget = nil
                self.movieOutput = nil
                
                self.popupMessage(title: nil, message: "Video Saved", duration: 500)
                //self.flashScreen()
            }
            
            videoButton.setImage(UIImage(named: "video_enabled"), for: .normal)
            photoButton.setImage(UIImage(named: "photo_enabled"), for: .normal)
            photoButton.isEnabled = true
            slideshowButton.setImage(UIImage(named: "slideshow_enabled"), for: .normal)
            slideshowButton.isEnabled = true
            toolsButton.setImage(UIImage(named: "toolbox_enabled"), for: .normal)
            toolsButton.isEnabled = true
        }
    }
    
    @IBAction func photoButtonClick(_ sender: UIButton) {
        print("photo button clicked")
        self.takePhoto { (image) in
            DispatchQueue.main.async {
                self.flashScreen()
            }
            
            self.lastPictureImage = image
            
            if self.isVideoRecording == true {
                self.updateSlideshowImage()
            }
        }
    }
    
    @IBAction func slideshowButtonClick(_ sender: UIButton) {
        
        if isVideoRecording == false {
            isVideoRecording = true
            videoRecordingOrientation = imageOrientation
            
            videoButton.setImage(UIImage(named: "video_disabled"), for: .normal)
            videoButton.isEnabled = false
            slideshowButton.setImage(UIImage(named: "slideshow_stop"), for: .normal)
            toolsButton.setImage(UIImage(named: "toolbox_disabled"), for: .normal)
            toolsButton.isEnabled = false
            
            flashScreen()

            self.takePhoto(completion: { (image) in
                DispatchQueue.main.async {
                    self.lastPictureImage = image

                    self.currentSlideshowInput = PictureInput(image: self.lastPictureImage)

                    self.slideShowBlendFilter = SourceOverBlend()

                    self.directoryHandler.createDirectory(dirType: .slideshows)
                    self.fileURL = URL(fileURLWithPath: "Slideshows/\(self.createTimestamp()).mp4", relativeTo: self.directoryHandler.getDocumentsPath())

                    do {
                        try FileManager.default.removeItem(at: self.fileURL!)
                    }
                    catch {

                    }

                    self.slideshowMovieOutput = try! MovieOutput(URL: self.fileURL!, size: Size(width: 1080, height: 1920), liveVideo: true)
                    print("after 1")
                    self.camera.audioEncodingTarget = self.slideshowMovieOutput

                    self.camera --> self.slideShowBlendFilter
                    self.currentSlideshowInput --> self.slideShowBlendFilter --> self.slideshowMovieOutput

                    self.currentSlideshowInput.processImage()
                    self.slideshowMovieOutput.startRecording()
                }
            })
        }
        else {
            isVideoRecording = false
            
            slideshowMovieOutput.finishRecording() {
                self.camera.audioEncodingTarget = nil
                self.slideshowMovieOutput = nil
                
                //UISaveVideoAtPathToSavedPhotosAlbum(self.fileURL.path, nil, nil, nil)
                
                self.popupMessage(title: nil, message: "Slideshow Saved", duration: 500)
                //self.flashScreen()
            }
            
            videoButton.setImage(UIImage(named: "video_enabled"), for: .normal)
            videoButton.isEnabled = true
            slideshowButton.setImage(UIImage(named: "slideshow_enabled"), for: .normal)
            toolsButton.setImage(UIImage(named: "toolbox_enabled"), for: .normal)
            toolsButton.isEnabled = true
        }
        
    }
    
//    @IBAction func filesButtonClick(_ sender: UIButton) {
//        let fileListController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FileListController") as? FileListController
//
//        fileListController?.passUploaderToMainView = { uploader in
//            print("Dropbox client passed back to MainView")
//            self.dropboxUploader = uploader
//        }
//
//        if let uploader = dropboxUploader {
//            fileListController?.dropboxUploader = uploader
//        }
//
//        DropboxClientsManager.unlinkClients()
//
//        present(fileListController!, animated: true, completion: nil)
        
//        //let myDocumentsList = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        //let myDocumentsDir = myDocumentsList[0]
//        //print(myDocumentsDir)
//
//        showDocumentsPicker()
//    }
    
    @IBAction func toolsButtonClick(_ sender: UIButton) {
        var rotationAngle = 0.0
        if imageOrientation == UIImageOrientation.left {
            rotationAngle = 90 * Double.pi / 180
        }
        else if imageOrientation == UIImageOrientation.right {
            rotationAngle = -90 * Double.pi / 180
        }
        
        let toolsMenu = CustomUIAlertController(title: "Tools", message: nil, preferredStyle: .alert)
        
        let filesOption = UIAlertAction(title: "File Viewer", style: .default) { (_) in
            self.showDocumentsPicker()
        }
        
        let imagePrefixOption = UIAlertAction(title: "Set Photo Name Prefix", style: .default) { (_) in
            self.getImagePrefixInput()
        }
        
        // add attributes on/off option here
        
        let offOnComment = userSettingsModel.getAskForImageComment() ? "OFF" : "ON"
        let imageCommentOption = UIAlertAction(title: "Turn \(offOnComment) Photo Comment", style: .default) { (_) in
            
            let isAskingForImageComment = self.userSettingsModel.getAskForImageComment()
            self.userSettingsModel.setAskForImageComment(value: !isAskingForImageComment)
        }
        
//        let onOffCoordinates = (updateCoordinates) ? "OFF": "ON"
//        let updateCoordinatesOption = UIAlertAction(title: "Turn \(onOffCoordinates) Location Updates", style: .default) { (_) in
//
//            self.updateCoordinates = !self.updateCoordinates
//        }
        
        let imageAttributesOption = UIAlertAction(title: "Edit Image Attributes", style: .default) { (_) in
            // attributes code goes here
            
            let ac = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AttributeViewController") as! AttributeViewController
            
            self.present(ac, animated: true, completion: nil)
        }
        
        let objectSizeOption = UIAlertAction(title: "Measure Object Size", style: .default) { (_) in
            self.getObjectSize()
        }
        
        let cancelOption = UIAlertAction(title: "Cancel", style: .default) { (_) in
            
            toolsMenu.dismiss(animated: false, completion: nil)
        }
        
        
        
        toolsMenu.addAction(filesOption)
        toolsMenu.addAction(imagePrefixOption)
        toolsMenu.addAction(imageCommentOption)
        toolsMenu.addAction(imageAttributesOption)
        //toolsMenu.addAction(updateCoordinatesOption)
        toolsMenu.addAction(objectSizeOption)
        toolsMenu.addAction(cancelOption)
        toolsMenu.rotationAngle = rotationAngle
        toolsMenu.view.alpha = 0.0
        
        present(toolsMenu, animated: ((rotationAngle == 0.0) ? true : false)) {
//            UIView.animate(withDuration: 0.25, animations: {
//                toolsMenu.view.alpha = 1.0
//                toolsMenu.view.transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle))
//            })
        }
    }
    
    
    @IBAction func mapViewClick(_ sender: Any) {
        if isMapFullScreen == false {
            
            mapViewFrame = mapView.frame
            mapView.userTrackingMode = .none
            
            closeMapButton = {
                let button = UIButton(type: .roundedRect)
                button.frame = CGRect(x: mapView.superview!.bounds.width - 100,
                                              y: mapView.superview!.bounds.height - 50,
                                              width: 100,
                                              height: 50)
                button.layer.cornerRadius = 10
                
                button.backgroundColor = UIColor.white
                button.alpha = 0
                button.setTitle("Close", for: .normal)
                button.addTarget(self, action: #selector(ViewController.closeMapButtonClick), for: .touchUpInside)
                
                return button
            }()
            
            controlsContainer.isUserInteractionEnabled = false
            
            UIView.animate(withDuration: 0.3, animations: {
                self.mapView.frame = self.mapView.superview!.bounds
                self.controlsContainer.alpha = 0.25
            }, completion: { _ in
                self.mapView.addSubview(self.closeMapButton)
                UIView.animate(withDuration: 0.3, animations: {
                    self.closeMapButton.alpha = 1
                })
            })
        }
        
        isMapFullScreen = true
    }
    
    @objc func closeMapButtonClick() {
        //print("closeMapButton Clicked!")
        
        closeMapButton.removeFromSuperview()
        
        controlsContainer.isUserInteractionEnabled = true
        
        UIView.animate(withDuration: 0.3, animations: {
            self.mapView.frame = self.mapViewFrame
            self.controlsContainer.alpha = 1.0
        }) { (Bool) in
            //self.photoPreview.isHidden = false
        }
        
        mapView.userTrackingMode = .follow
        
        isMapFullScreen = false
    }

    @IBAction func cameraPreviewPinch(_ sender: UIPinchGestureRecognizer) {
        pinchZoomCamera(sender)
    }
    
    @IBAction func gpsSwitchClick(_ sender: UISwitch) {
        if gpsSwitch.isOn == true {
            updateCoordinates = true
        }
        else {
            updateCoordinates = false
        }
    }
    
    @IBAction func indexSwitchClick(_ sender: UISwitch) {
        if indexSwitch.isOn == true {
            if userSettingsModel.getImagePrefix() == nil {
                indexSwitch.setOn(false, animated: true)
            }
            else {
                lockFileIndex()
            }
        }
        else {
            unlockFileIndex()
        }
    }
    
    // MARK: - Push Notifications ----------------------------------------------------
    
    @objc func onDeviceRotation() {
        if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            if UIDevice.current.orientation == UIDeviceOrientation.portrait {
                imageOrientation = UIImageOrientation.up
                videoOrientation = CGFloat(0)
                
                //rotateButtons(orientation: imageOrientation)
                
                //print("orientation: portrait up")
            }
            else if UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown {
                imageOrientation = UIImageOrientation.down
                videoOrientation = CGFloat(-Double.pi)
                
                //print("orientation portrait down")
            }
        }
        else if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
                imageOrientation = UIImageOrientation.left
                videoOrientation = CGFloat(Double.pi / -2)
                
                //print("orientation: landscape left")
            }
            else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                imageOrientation = UIImageOrientation.right
                videoOrientation = CGFloat(Double.pi / 2)
                
                //print("orientation: landscape right")
            }
        }
    }
    
    @objc func onDidReceiveCoordinates(_ notification: Notification) {
        
        if locationFinder!.latitude == nil || locationFinder.longitude == nil {
            return
        }
        
        //let (dmsLatitude, dmsLongitude) = locationFinder.decimalToDMSString(latitude: locationFinder.latitude, longitude: locationFinder.longitude)
        if updateCoordinates == true {
            (currentLatitudeString, currentLongitudeString) = locationFinder.decimalToDMSString(latitude: locationFinder.latitude, longitude: locationFinder.longitude)
        }
        
        updateCoordinatesOverlay(latitude: NSString(string: currentLatitudeString), longitude: NSString(string: currentLongitudeString), cardinalDirection: locationFinder.getCardinalDirection())
        
//        overlayBlender.removeSourceAtIndex(0)
//        compassNeedlePictureInput.addTarget(overlayBlender)
//        compassNeedlePictureInput.processImage()
        
        chromaFilter.removeSourceAtIndex(0)
        coordinatesOverlay.addTarget(chromaFilter)
        coordinatesOverlay.processImage()
    }
    
    func locationChange() {
        if locationFinder!.latitude == nil || locationFinder.longitude == nil {
            return
        }
        
        if updateCoordinates == true {
            currentLatitudeDouble = locationFinder.latitude
            currentLongitudeDouble = locationFinder.longitude
            
            (currentLatitudeString, currentLongitudeString) = locationFinder.decimalToDMSString(latitude: currentLatitudeDouble, longitude: currentLongitudeDouble)
        }
        
        updateCoordinatesOverlay(latitude: NSString(string: currentLatitudeString), longitude: NSString(string: currentLongitudeString), cardinalDirection: locationFinder.getCardinalDirection())

        chromaFilter.removeSourceAtIndex(0)
        coordinatesOverlay.addTarget(chromaFilter)
        coordinatesOverlay.processImage()
    }
    
// MARK: - UI Updating -----------------------------------------------------------
    
    func updateCoordinatesOverlay(latitude: NSString, longitude: NSString, cardinalDirection: String!) {
        let screenWidth: CGFloat = UIScreen.main.bounds.width
        let screenHeight: CGFloat = UIScreen.main.bounds.height
        
        var context: CGContext!
        
        //var overlayRect: CGRect!
        var overlayOrigin: CGPoint!
        var overlayRotation: CGFloat = 0
        var overlayWidth: CGFloat!
        var overlayHeight: CGFloat!
        
        let leftRotationAngle: CGFloat = CGFloat(90 * Double.pi / 180)
        let rightRotationAngle: CGFloat = CGFloat(-90 * Double.pi / 180)
        
        var coordinatesBoxRatio: [String: CGFloat] = ["width": 0.0, "height": 0.0]
        var directionBoxRatio: [String: CGFloat] = ["width": 0.0, "height": 0.0]

        // check for video currently recording
        var currentOrientation: UIImageOrientation!
        if isVideoRecording == true {
            currentOrientation = videoRecordingOrientation
        }
        else {
            currentOrientation = imageOrientation
        }
        
        // set landscape mode overlay sizes/ratios
        if (currentOrientation == UIImageOrientation.left) || (currentOrientation == UIImageOrientation.right) {
            if currentOrientation == UIImageOrientation.left {
                overlayOrigin = CGPoint(x: screenWidth, y: 0)
            }
            else if currentOrientation == UIImageOrientation.right {
                overlayOrigin = CGPoint(x: 0, y: screenHeight)
            }

            overlayWidth = screenHeight
            overlayHeight = screenWidth
            
            coordinatesBoxRatio["width"] = 0.32
            coordinatesBoxRatio["height"] = 0.25
            
            //directionBoxRatio["width"] = 0.125
            //directionBoxRatio["height"] = 0.15

            overlayRotation = (currentOrientation == UIImageOrientation.left) ? leftRotationAngle : rightRotationAngle
        }
        // set portrait mode overlay sizes/ratios
        else {
            overlayOrigin = CGPoint(x: 0, y: 0)

            overlayWidth = screenWidth
            overlayHeight = screenHeight
            
            coordinatesBoxRatio["width"] = 0.5
            coordinatesBoxRatio["height"] = 0.15
            
            //directionBoxRatio["width"] = 0.20
            //directionBoxRatio["height"] = 0.075
        }
        
        UIGraphicsBeginImageContext(UIScreen.main.bounds.size)
        context = UIGraphicsGetCurrentContext()
        
        context.translateBy(x: overlayOrigin.x, y: overlayOrigin.y)
        context.rotate(by: overlayRotation)
        
        //create black rectangle for coordinates black box
        let coordinatesBlackRect = CGRect(
            x: 0,
            y: overlayHeight - (overlayHeight * coordinatesBoxRatio["height"]!),
            width: overlayWidth * coordinatesBoxRatio["width"]!,
            height: overlayHeight * coordinatesBoxRatio["height"]!
        )
        // curve edges of coordinates black box
        let coordinatesBlackRectClipPath = UIBezierPath(roundedRect: coordinatesBlackRect, byRoundingCorners: .topRight, cornerRadii: CGSize(width: 20, height: 20)).cgPath
        // draw coordinates black box on bitmap
        context.addPath(coordinatesBlackRectClipPath)
        context.setFillColor(UIColor.black.cgColor)
        context.setAlpha(1.0)
        context.closePath()
        context.fillPath()
        
        let font = "Helvetica" // used to be "Futura"
        let coordinateFontColor  = (updateCoordinates == true) ? UIColor.white : UIColor.red
        //set font for on-screen coordinates stamp
        let coordinateFontAttrs = [
            NSAttributedString.Key.font: UIFont(name: font, size: 22),
            NSAttributedString.Key.foregroundColor: coordinateFontColor
        ]
        //draw coordinates on bitmap
        latitude.draw(at:CGPoint(x: coordinatesBlackRect.origin.x + 5, y: coordinatesBlackRect.origin.y), withAttributes: coordinateFontAttrs as [NSAttributedString.Key : Any])
        longitude.draw(at: CGPoint(x: coordinatesBlackRect.origin.x + 5, y: coordinatesBlackRect.origin.y + 25), withAttributes: coordinateFontAttrs as [NSAttributedString.Key : Any])
        "Heading: \(cardinalDirection!)".draw(at: CGPoint(x: coordinatesBlackRect.origin.x + 5 , y: coordinatesBlackRect.origin.y + 50), withAttributes: [NSAttributedString.Key.font: UIFont(name: font, size: 22), NSAttributedString.Key.foregroundColor: UIColor.white])
        
        // create time formatter for on-screen timestamp
        let timeStampFormatter = DateFormatter()
        timeStampFormatter.dateFormat = "M/dd/yyyy, h:mm:ss a"
        let timestamp = timeStampFormatter.string(from: Date())
        
        // set font for on-screen timestamp
        let timestampFontAttrs = [
            NSAttributedString.Key.font: UIFont(name: font, size: 16),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        // draw timestamp on bitmap
        "\(timestamp)".draw(at: CGPoint(x: coordinatesBlackRect.origin.x + 5, y: coordinatesBlackRect.origin.y + 80), withAttributes: timestampFontAttrs as [NSAttributedString.Key : Any])
        
        // get bitmap from the image context
        let coordinatesImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        coordinatesOverlay = PictureInput(image: coordinatesImage!)
        
        rotateButtons(orientation: imageOrientation)
    }
    
    func updateMap() {
        if locationFinder?.latitude == nil || locationFinder?.longitude == nil {
            return
        }
        
        mapView.mapType = .satellite
        mapView.showsUserLocation = true
        
        if isMapFullScreen == false {
        
            let regionRadius: CLLocationDistance = 25
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: locationFinder.latitude, longitude: locationFinder.longitude), regionRadius, regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
        }
        else {
            //mapView.userTrackingMode = .none
        }
    }
    
    func flashScreen() {
        let flashView = UIImageView(frame: UIScreen.main.bounds)
        flashView.backgroundColor = UIColor.white
        self.view.addSubview(flashView)
        
        UIView.animate(withDuration: 0.25, animations: {
            flashView.alpha = 0.0
        }) { _ in
            flashView.removeFromSuperview()
        }
    }
    
// MARK: - Helper functions ------------------------------------------------------
    
    func updateSlideshowImage() {
        currentSlideshowInput.removeAllTargets()
        currentSlideshowInput = PictureInput(image: lastPictureImage)
        
        currentSlideshowInput.addTarget(slideShowBlendFilter)
        currentSlideshowInput.processImage()

        //print("updated slideshow image!!!")
    }
    
    func setCameraDevice() {
        var device: AVCaptureDevice?
        
        func setCameraObject(device: AVCaptureDevice) {
            do {
                //self.camera = try Camera(sessionPreset: .hd1920x1080, cameraDevice: device, location: .backFacing, captureAsYUV: true)
                self.camera = try Camera(sessionPreset: .hd1920x1080, cameraDevice: device, location: .backFacing, orientation: ImageOrientation.portrait, captureAsYUV: true)
                
            } catch {
                print("setCameraObject: Could not create camera object.")
                fatalError("ERROR: Could not create camera object.")
            }
        }
        
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
            
            if device.isSmoothAutoFocusSupported == true {
                try! device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            }
            
            setCameraObject(device: device)
            
            //return device
        }
        else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            
            if device.isSmoothAutoFocusSupported == true {
                try! device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            }
            
            setCameraObject(device: device)
            //return device
        }
        else {
            print("setCameraDevice() could not get a device!")
            fatalError("ERROR: Could not get capture device!")
        }
        
    }
    
    func popupMessage(title: String?, message: String?, duration: Int?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // if no duration, then add OK button
        if duration == nil {
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
        }
        
        present(alert, animated: true) {
            if duration != nil {
                usleep(useconds_t(1000 * duration!))
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func createTimestamp() -> String {
        let timestampFormatter = DateFormatter()
        timestampFormatter.timeZone = TimeZone.current
        timestampFormatter.dateFormat = "HHmmssMMddyyyy"
        
        let timestamp = timestampFormatter.string(from: Date())
        
        return timestamp
    }
    
    func takePhoto(completion: @escaping (UIImage) -> Void) {
        self.pictureOutput = PictureOutput()
        self.pictureOutput.encodedImageFormat = .png
        self.pictureOutput.imageAvailableCallback = { outputImage in
            
            // lock coordinates to save into saved image file
            let lockedLatitude = self.currentLatitudeDouble
            let lockedLongitude = self.currentLongitudeDouble
            
            //set orientation of the output image
            let newSizedImage = UIImage(cgImage: outputImage.cgImage!, scale: 1.0, orientation: self.imageOrientation)
            
            //redraw new image to correct orientation
            UIGraphicsBeginImageContext(newSizedImage.size)
            newSizedImage.draw(in: CGRect(x: 0, y: 0, width: newSizedImage.size.width, height: newSizedImage.size.height))
            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            //DispatchQueue.main.async {
                completion(outputImage)
            //}
        
            self.directoryHandler.createDirectory(dirType: .photos)
//            let fileURL = URL(fileURLWithPath: "Photos/\(self.createTimestamp()).png", relativeTo: self.directoryHandler.getDocumentsPath())
            let fileURL = URL(fileURLWithPath: "Photos/\(self.getFilename()).png", relativeTo: self.directoryHandler.getDocumentsPath())
            
            //let jpg = UIImageJPEGRepresentation(image, 1.0)
            let png = UIImagePNGRepresentation(finalImage!)
            
            do {
                //try png?.write(to: fileURL)
                try png?.write(to: fileURL, options: .withoutOverwriting)
                
//                DispatchQueue.main.async {
//                    self.setFilenameLabelText()
//                }
                
                self.getImageComment(completion: { (comment) in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "M/dd/yyyy, h:mm:ss a"
                    dateFormatter.timeZone = TimeZone.current
                    let fileCreationDate = dateFormatter.string(from: Date())
                    
                    let exifParams = EXIFDataParams(latitude: lockedLatitude, longitude: lockedLongitude, creationDateTime: fileCreationDate, comment: comment)
                    
                    let exifDataRaderWriter = EXIFDataReaderWriter()
                    exifDataRaderWriter.writeEXIFDataToPhoto(fileURL: fileURL, image: png!, exifDataParams: exifParams)
                })
            }
            catch let error as NSError{
                if error.code == 516 {
                    self.popupMessage(title: "Error", message: "Could not save file. A file with that name already exists.", duration: nil)
                }
                else {
                    self.popupMessage(title: "Error", message: "Could not save file.", duration: nil)
                }
            }
            
//            self.getImageComment(completion: { (comment) in
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "M/dd/yyyy, h:mm:ss a"
//                dateFormatter.timeZone = TimeZone.current
//                let fileCreationDate = dateFormatter.string(from: Date())
//
//                let exifParams = EXIFDataParams(latitude: self.locationFinder.latitude, longitude: self.locationFinder.longitude, creationDateTime: fileCreationDate, comment: comment)
//
//                let exifDataRaderWriter = EXIFDataReaderWriter()
//                exifDataRaderWriter.writeEXIFDataToPhoto(fileURL: fileURL, image: png!, exifDataParams: exifParams)
//            })
            
            DispatchQueue.main.async {
                self.setFilenameLabelText()
            }
            
            self.pictureOutput = nil
            
            print("image saved!")

        }
        
        //self.blendFilter --> self.pictureOutput
        self.cameraOverlayBlendFilter --> self.pictureOutput
    }
    
    @IBAction func pinchZoomCamera(_ sender: UIPinchGestureRecognizer) {
        guard let device = camera.inputCamera else { return }
        
        let minFactor = device.minAvailableVideoZoomFactor
        let maxFactor = device.maxAvailableVideoZoomFactor
        
        var factorDiff = sender.scale - 1.0
        
        if factorDiff < 0 { factorDiff = factorDiff * 3 }
        
        var newFactor = lastZoomFactor + factorDiff
        
        if newFactor < minFactor {
            newFactor = 1.0
        } else if newFactor > 10.0 {
            newFactor = 10.0
        }

        let zoom = {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
                device.videoZoomFactor = newFactor
                
                self.zoomLabel.text = String(format: "Zoom x%0.1f", newFactor)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        switch sender.state {
            case .began: break
            case .changed: zoom()
            case .ended: zoom()
                lastZoomFactor = device.videoZoomFactor
            default: break
        }
    }
    
    func animateSplashScreen() {
        appNameImage.transform = CGAffineTransform(scaleX: 0, y: 0)
        splashScreenContainer.isHidden = false
        
        UIView.animate(withDuration: 0.75, delay: 0.5, usingSpringWithDamping: 0.5, initialSpringVelocity: 30, options: .curveEaseOut, animations: {
            print("start pop app name")
            self.appNameImage.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            print("end pop app name")
        }, completion: { _ in
            print("dispatching sleep thread")
            DispatchQueue.global().async {
                print("sleeping splash screen")
                usleep(1000 * 3000)
                
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.splashScreenContainer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                        self.splashScreenContainer.alpha = 0.1
                    }, completion: { _ in
                        self.splashScreenContainer.isHidden = true
                    })
                }
            }
        })
    }
    
    func rotateButtons(orientation: UIImageOrientation) {
        var rotationAngle: CGFloat = 0.0
        
        let cameraViewWidth: CGFloat = cameraView.frame.width
        let cameraViewHeight: CGFloat = cameraView.frame.height
        
        //var filenameLabelFrame: CGRect = filenameLabel.frame
        let filenameLabelSpacer: CGFloat = 10
        var filenameLabelAnchor = filenameLabel.layer.anchorPoint
        var filenameLabelPosition = filenameLabel.layer.position
        
        var switchesContainerAnchor = switchesContainer.layer.anchorPoint
        var switchesContainerPosition = switchesContainer.layer.position
        
        if (orientation == .up) || (orientation == .down) {
            filenameLabelAnchor = CGPoint(x: 0, y: 0)
            filenameLabelPosition = CGPoint(x: filenameLabelSpacer, y: filenameLabelSpacer)
            
            switchesContainerAnchor = CGPoint(x: 1, y: 1)
            switchesContainerPosition = CGPoint(x: cameraViewWidth, y: cameraViewHeight)
            
            rotationAngle = CGFloat(0.0)
        }
        else if orientation == .left {
            
            filenameLabelAnchor = CGPoint(x: 0, y: 0)
            filenameLabelPosition = CGPoint(x: cameraViewWidth - filenameLabelSpacer, y: filenameLabelSpacer)
            
            switchesContainerAnchor = CGPoint(x: 1, y: 1)
            switchesContainerPosition = CGPoint(x: 0, y: cameraViewHeight)
            
            rotationAngle = CGFloat(90 * Double.pi / 180)
            
        }
        else if orientation == .right {
            filenameLabelAnchor = CGPoint(x: 0, y: 0)
            filenameLabelPosition = CGPoint(x: filenameLabelSpacer, y: cameraViewHeight - filenameLabelSpacer)
            
            switchesContainerAnchor = CGPoint(x: 1, y: 1)
            switchesContainerPosition = CGPoint(x: cameraViewWidth, y: 0)
            
            rotationAngle = CGFloat(-90 * Double.pi / 180)
        }
        
        UIView.animate(withDuration: 0.25) {
            // anchor/position/rotate controls ------------------
            self.filenameLabel.layer.anchorPoint = filenameLabelAnchor
            self.filenameLabel.layer.position = filenameLabelPosition
            self.filenameLabel.transform = CGAffineTransform(rotationAngle: rotationAngle)
            
            self.switchesContainer.layer.anchorPoint = switchesContainerAnchor
            self.switchesContainer.layer.position = switchesContainerPosition
            self.switchesContainer.transform = CGAffineTransform(rotationAngle: rotationAngle)
            
            self.toolsButton.transform = CGAffineTransform(rotationAngle: rotationAngle)
            self.videoButton.transform = CGAffineTransform(rotationAngle: rotationAngle)
            self.slideshowButton.transform = CGAffineTransform(rotationAngle: rotationAngle)
            self.photoButton.transform = CGAffineTransform(rotationAngle: rotationAngle)
        }
    }
    
    func showDocumentsPicker() {
        let pickerController = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        pickerController.allowsMultipleSelection = true
        pickerController.delegate = self
        
        present(pickerController, animated: true, completion: nil)
    }
    
    func showDocumentsOptionMenu(urls: [URL]) {
        let popupMenu = UIAlertController(title: "\(urls.count) File(s) Selected", message: nil, preferredStyle: .actionSheet)
        
        
        popupMenu.addAction(UIAlertAction(title: "Upload", style: .default, handler:{ _ in
            //print("Upload button pressed")
            
            let uploadBatchFiles = {
                let folder = "/\(self.directoryHandler.currentDirectory.lastPathComponent)"
                //var urlList: [URL]! = []
                
//                for indexPath in selectedIndexes! {
//                    let filename = (self.tableView.cellForRow(at: indexPath) as! CustomFileListCell).cellFilenameLabel.text!
//                    let url = URL(string: "\(self.directoryHandler.currentDirectory!)\(filename)")!
//                    urlList.append(url)
//                }
                
                //here lies the problem with kristen's phone?
                self.dropboxUploader.uploadBatchFilesToDropBox(controller: self, urls: urls, folder: folder, completion: nil)
            }
            
            if self.dropboxUploader == nil || self.dropboxUploader.dropboxClient == nil {
                self.dropboxUploader = DropboxUploader()
                self.dropboxUploader.startAuthorizationFlow(controller: self) {
                    uploadBatchFiles()
                }
            } else {
                uploadBatchFiles()
            }
        }))
        
//-------------------------------------------------------------------------
//        popupMenu.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in
//
//            let fileManager = FileManager.default
//
//            for url in urls {
//
//                let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
//                var documentsDirectory = paths[0]
//
//                print("URL passed: ", url)
//                print("App URL: ", documentsDirectory)
//            documentsDirectory.appendPathComponent(documentsDirectory.lastPathComponent)
//
//                //print("Appended directory")
//
//                print("Current Directory: ", documentsDirectory.absoluteURL)
//            fileManager.changeCurrentDirectoryPath(documentsDirectory.absoluteString)
//
//                do {
//                    print("Deleting: ", url.lastPathComponent)
//                    try fileManager.removeItem(atPath: url.lastPathComponent)                }
//                catch let error {
//                    print("Error (delete file): ", error)
//                }
//            }
//        }))
        
        popupMenu.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
            popupMenu.dismiss(animated: true, completion: nil)
            self.showDocumentsPicker()
        }))

        present(popupMenu, animated: true, completion: nil)
    }
    //----------------------------------------
    func getImagePrefixInput() {
        let popupInputMessage = UIAlertController(title: "Enter photo prefix", message: nil, preferredStyle: .alert)
        
        popupInputMessage.addTextField { (textField) in
            textField.placeholder = "Prefix"
            textField.text = self.userSettingsModel.getImagePrefix()
        }

        popupInputMessage.addTextField { (textField) in
            textField.placeholder = "Count"
            //textField.text = self.userSettingsModel.getImageNumber()
            textField.text = String(self.fileCount)
        }
        
        let prefixTextField = popupInputMessage.textFields![0]
        let counterTextField = popupInputMessage.textFields![1]
        
        let okButton = UIAlertAction(title: "OK", style: .default) { (_) in
            //let invalidCharSet: [Character] = ["\\", "/", "?", "%", "*", ":", "|", "\"", "<", ">", ".", " ", ",", "!", "~"]
            var suggestedPrefix = prefixTextField.text
            
            suggestedPrefix = suggestedPrefix?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // if prefix is the same
            if suggestedPrefix == self.userSettingsModel.getImagePrefix() {
                // do nothing
            }
            //if prefix is empty make it the timestamp
            else if suggestedPrefix?.count == 0 {
                self.userSettingsModel.setImagePrefix(prefix: nil)
                
                self.fileCount = 0
                self.unlockFileIndex()
            }
                // set new prefix after validating text format
            else {
                let regex = try! NSRegularExpression(pattern: "[^A-Za-z0-9_-]")
                let range = NSRange(location: 0, length: suggestedPrefix!.utf16.count)
                
                // if prefix text format is valid
                if regex.firstMatch(in: suggestedPrefix!, options: [], range: range) == nil {
                    self.userSettingsModel.setImagePrefix(prefix: suggestedPrefix!)
                    self.fileCount = 0
                    self.unlockFileIndex()
                    counterTextField.text = "0"
                }
                else {
                    self.popupMessage(title: "File Prefix", message: "Invalid filename!", duration: nil)
                }
            }
            
            if counterTextField.text != "" {
                if let count = Int(counterTextField.text!) {
                    self.unlockFileIndex()
                    self.fileCount = count
                }
            }
            
            self.setFilenameLabelText()
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            //cancel button code here
        }
        
        popupInputMessage.addAction(okButton)
        popupInputMessage.addAction(cancelButton)
        
        present(popupInputMessage, animated: true, completion: nil)
    }
    
    func getImageComment(completion: @escaping (String) -> Void){
        
        if userSettingsModel.getAskForImageComment() {
            let commentAlert = UIAlertController(title: "Image Comment", message: "Enter a comment for the image:", preferredStyle: .alert)
            
            commentAlert.addTextField(configurationHandler: nil)
            
            let okAction = UIAlertAction(title: "OK", style: .default) { (alertAction) in
                if commentAlert.textFields![0].hasText {
                    let comment = commentAlert.textFields![0].text!
                    
                    completion(comment)
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) in
                completion("")
            }
            
            commentAlert.addAction(okAction)
            commentAlert.addAction(cancelAction)
            
            present(commentAlert, animated: true, completion: nil)
        }
        else {
            completion("")
        }
    }
    
    func getFilename() -> String {
        var filename: String? = userSettingsModel.getImagePrefix()
        
        if filename == nil {
            filename = createTimestamp()
        }
        else {
            filename = filename! + String(format: fileCountFormat, fileCount) + getFileIndexLetter(increment: true)
            
            if fileCountIndex == 0 {
                fileCount = fileCount + 1
            }
        }
        
        return filename!
    }
    
    func setFilenameLabelText() {
        if let filePrefix = userSettingsModel.getImagePrefix() {
            filenameLabel.text = "\(filePrefix)\(String(format: fileCountFormat, fileCount))\(getFileIndexLetter(increment: false)).png"
        }
        else {
            filenameLabel.text = "(timestamp)"
        }
        
        return
    }
    
    func getObjectSize() {
        if (UIDevice.current.orientation != UIDeviceOrientation.portrait) {
            popupMessage(title: "Object Measure", message: "Cannot get measurements in landscape mode.", duration: 3)
        }
        
        angleReader.startTrackingDeviceMotion()
        angleReader.startTrackingDeviceRelativeAltitude()
        
        let buttonWidth = CGFloat(50)
        let buttonHeight  = CGFloat(50)
        let buttonX = CGFloat((UIScreen.main.bounds.width - buttonWidth) / 2)
        let buttonY = CGFloat((UIScreen.main.bounds.height - buttonHeight) / 2)
        let dotButtonFrame = CGRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight)
        let dotButton: UIButton = UIButton(frame: dotButtonFrame)
        dotButton.setTitle("+", for: .normal)
        dotButton.backgroundColor = UIColor.green
        dotButton.alpha = 0.5
        
        dotButton.layer.cornerRadius = buttonWidth / 2
        dotButton.addTarget(self, action: #selector(getPitch), for: .touchUpInside)
        
        view.addSubview(dotButton)
        view.bringSubview(toFront: dotButton)
        
        videoButton.isEnabled = false
        videoButton.setImage(UIImage(named: "video_disabled"), for: .normal)
        slideshowButton.isEnabled = false
        slideshowButton.setImage(UIImage(named: "slideshow_disabled"), for: .normal)
        photoButton.isEnabled = false
        photoButton.setImage(UIImage(named: "photo_disabled"), for: .normal)
        toolsButton.isEnabled = false
        toolsButton.setImage(UIImage(named: "toolbox_disabled"), for: .normal)
        
        let timer = Timer(timeInterval: 0.25, repeats: true) { (timer) in
            if (self.angleReader.getCurrentPitch() < 0) {
                dotButton.backgroundColor = UIColor.red
                dotButton.isEnabled = false
            }
            else {
                dotButton.backgroundColor = (self.angleReader.angle1 == nil) ? UIColor.green : UIColor.blue
                dotButton.isEnabled = true
            }
            
            if self.angleReader.angle2 != nil {
                dotButton.removeFromSuperview()
                
                self.videoButton.isEnabled = true
                self.videoButton.setImage(UIImage(named: "video_enabled"), for: .normal)
                self.slideshowButton.isEnabled = true
                self.slideshowButton.setImage(UIImage(named: "slideshow_enabled"), for: .normal)
                self.photoButton.isEnabled = true
                self.photoButton.setImage(UIImage(named: "photo_enabled"), for: .normal)
                self.toolsButton.isEnabled = true
                self.toolsButton.setImage(UIImage(named: "toolbox_enabled"), for: .normal)
                
                timer.invalidate()
            }
        }
        
        RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
        
        //popupMessage(title: "Object Measure", message: "Hold phone at eye level and rotate it until the button in the middle turns green, then press the button.", duration: nil)
        
        popupMessage(title: "Object Measure", message: "1. Point the green button at the bottom left corner of the object and then tap it.\n2. When the button is blue, point the button at the top right corner of the object and then tap it.", duration: nil)
        
    }
    
    @objc func getPitch() {
//        let currentPitch = angleReader.getCurrentPitch()
//
//        if angleReader.pitch1 == nil {
//            if currentPitch > 87.5 {
//                angleReader.pitch1 = angleReader.getCurrentPitch()
//                popupMessage(title: "Object Measure", message: "First pitch: \(currentPitch)\nNow center the button at the top of the object and press it once it's green.", duration: nil)
//            }
//        }
//        else {
//            if currentPitch > 0.0 {
//                angleReader.pitch2 = angleReader.getCurrentPitch()
//                print("pitch2: ", currentPitch)
//
//                let angle = angleReader.pitch1! - angleReader.pitch2!
//
//                print("angle: ", angle)
//
//                angleReader.stopTrackingDeviceMotion()
//                //angleReader.clearPitches()
//
//                //popupMessage(title: "Object Measure", message: "Got second pitch: \(currentPitch)", duration: nil)
//
//
//                let getDistanceAlert = UIAlertController(title: "Object Measure", message: "Enter your height and distance to the object.", preferredStyle: .alert)
//                getDistanceAlert.addTextField()
//                getDistanceAlert.textFields![0].placeholder = "Height"
//                getDistanceAlert.addTextField()
//                getDistanceAlert.textFields![1].placeholder = "Distance"
//
//                let okButton = UIAlertAction(title: "OK", style: .default) { (_) in
//                    let height = Double(getDistanceAlert.textFields![0].text!)
//                    let distance = Double(getDistanceAlert.textFields![1].text!)
//
//                    print("Distance: ", distance!)
//                    print("Height: ", height!)
//
//                    var objectHeight = (tan(angle * Double.pi / 180) * distance! + height!)
//                    objectHeight = Double(round(objectHeight * 100))
//                    objectHeight = objectHeight / 100
//                    print("objectHeight: ", objectHeight)
//
//                    self.popupMessage(title: "Object Measure", message: "Object height is \(objectHeight) feet.", duration: nil)
//
//                }
//
//                getDistanceAlert.addAction(okButton)
//
//                present(getDistanceAlert, animated: true, completion: nil)
//
//                //popupMessage(title: "Object Measure", message: "Angle: \(angle)", duration: nil)
//            }
//        }
        
        if angleReader.angle1 == nil {
            angleReader.angle1 = angleReader.getCurrentAngle(heading: locationFinder.heading, altitude: angleReader.getCurrentRelativeAltitude())
            //print("Angle1 -----> \t\t pitch: \(angleReader.angle1?.pitch) \t\tgravity: \(angleReader.angle1?.gravity)") //////////////
            
            //popupMessage(title: "Object Height", message: "Point the dot at the top of the object and then tap it.", duration: nil)
        }
        else if angleReader.angle2 == nil {
            angleReader.angle2 = angleReader.getCurrentAngle(heading: locationFinder.heading, altitude: angleReader.getCurrentRelativeAltitude())
            //print("Angle1 -----> \t\t pitch: \(angleReader.angle2?.pitch) \t\tgravity: \(angleReader.angle2?.gravity)") //////////////
            
            let distanceAlert = UIAlertController(title: "Object Measure", message: "Enter your distance in feet from the object. (ex: 10 or 2.5)", preferredStyle: .alert)
            
            distanceAlert.addTextField(configurationHandler: nil)
            
            let okbutton = UIAlertAction(title: "OK", style: .default) { (_) in
                let distanceText = distanceAlert.textFields![0].text
                
//                let regex = try! NSRegularExpression(pattern: "[^0-9.]")
//                let range = NSRange(location: 0, length: distanceText!.count)
//                if regex.firstMatch(in: distanceText!, options: [], range: range) != nil {
//                    self.popupMessage(title: "Object Height", message: "Invalid object height.", duration: nil)
//
//                    self.angleReader.stopTrackingDeviceMotion()
//                    self.angleReader.clearAngles()
//
//                    return
//                }
                
                let distance: Double? = Double(distanceText!)
                if distance == nil {
                    self.popupMessage(title: "Object Measure", message: "Error: Invalid distance", duration: nil)
                }
                else {
                    var height = self.angleReader.getHeightFromAngles(angle1: self.angleReader.angle1!, angle2: self.angleReader.angle2!, distance: distance!)
                    var width = self.angleReader.getWidthFromAngles(angle1: self.angleReader.angle1!, angle2: self.angleReader.angle2!, distance: distance!)
                    height = round(height * 100) / 100
                    width = round(width * 100) / 100
                    
                    self.popupMessage(title: "Object Measure", message: "Approx. Height: \(height) ft.\n Approx. Width: \(width) ft.", duration: nil)
                }
                
                self.angleReader.stopTrackingDeviceMotion()
                self.angleReader.stopTrackingDeviceRelativeAltitude()
                self.angleReader.clearAngles()
            }
            
            let cancelButton = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
                self.angleReader.stopTrackingDeviceMotion()
                self.angleReader.stopTrackingDeviceRelativeAltitude()
                self.angleReader.clearAngles()
            }
            
            distanceAlert.addAction(okbutton)
            distanceAlert.addAction(cancelButton)
            present(distanceAlert, animated: true, completion: nil)
        }
    }
    
    func getFileIndexLetter(increment: Bool) -> String {
        var charStr = ""
        
        if fileCountIndex != 0 {
            if let uni = UnicodeScalar(fileCountIndex) {
                let char = Character(uni)
                charStr = String(char)
            }
            
            if increment == true {
                fileCountIndex += 1
                if fileCountIndex == 123 {
                    fileCountIndex = 97
                }
            }
        }
        
        return charStr
    }
    
    func lockFileIndex() {
        fileCountIndexIsLocked = true
        
        fileCountIndex = 97
        setFilenameLabelText()
    }
    
    func unlockFileIndex() {
        if fileCountIndexIsLocked == false {
            return
        }
        
        fileCountIndexIsLocked = false
        indexSwitch.setOn(false, animated: true)
        
        if fileCountIndex != 97 {
            fileCount += 1
        }
        
        fileCountIndex = 0
        setFilenameLabelText()
        
        
    }
}

extension ViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        UISaveVideoAtPathToSavedPhotosAlbum(fileURL.path, nil, nil, nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("ERROR: Audio recorder experienced error in encoding!!!!!!!!")
    }
}

extension ViewController: MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        popupMessage(title: "Map", message: "Map was loaded!", duration: 500)
    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        let fileManager = FileManager.default
        let tmpDirContents = try! fileManager.contentsOfDirectory(atPath: fileManager.temporaryDirectory.path)
        //print("items in tmp directory: ", tmpDirContents.count)
        for file in tmpDirContents {
            var fileURL = fileManager.temporaryDirectory
            fileURL.appendPathComponent(file)
            
            if fileURL.hasDirectoryPath {
                continue
            }
            
            try! fileManager.removeItem(atPath: fileURL.path)
        }
        
//        print("items in tmp directory after delete: ")
//        print(try! fileManager.contentsOfDirectory(atPath: fileManager.temporaryDirectory.path).count)
        
        
        var urlList = urls.map { (oldURL) -> URL in
            let fileManager = FileManager.default
            var newURL = fileManager.temporaryDirectory
            newURL.appendPathComponent(oldURL.lastPathComponent)
            
//            if fileManager.fileExists(atPath: newURL.path) {
//                print("\(newURL.lastPathComponent) exists!... removing")
//                try! fileManager.removeItem(at: newURL)
//            }
            try! fileManager.moveItem(at: oldURL, to: newURL)
            
            return newURL
        }

        if urlList.count == 1 {
            print("found only 1 item to share")
            let dc = UIDocumentInteractionController(url: urlList[0])
            dc.delegate = self
            dc.presentPreview(animated: true)
        }
        else {
            print("found \(urlList.count) items to share")
//            let ac = UIActivityViewController(activityItems: urlList, applicationActivities: nil)
//            ac.completionWithItemsHandler = {activityType, completed, returnedItems, activityError in
//                if completed == false {
//                    self.showDocumentsPicker()
//                }
//            }
//            present(ac, animated: true, completion: nil)
            
            showDocumentsOptionMenu(urls: urlList)
        }
    }
}

extension ViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        let pickerController = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        pickerController.allowsMultipleSelection = true
        pickerController.delegate = self
        
        present(pickerController, animated: true, completion: nil)
    }
}

extension UIAlertController {
    func dismissWithAnimation(animated animation: () -> (), completion: (() -> Void)? = nil) {
        animation()
        
        animation()
        dismiss(animated: true, completion: completion)
    }
    
//    override open func viewWillDisappear(_ animated: Bool) {
//        if animated == false {
//            self.view.isHidden = true
//        }
//    }
}

//extension UIImage {
//    func rotate(orientation: Orientation) -> UIImage? {
//        var newSize: CGSize!
//        if (orientation == .up) || (orientation == .down) {
//            newSize = self.size
//        }
//        else {
//            newSize = CGSize(width: self.size.height, height: self.size.width)
//        }
//
//        var rotationAngle: Double! = 0.0
//        if orientation == .left {
//            print("rotating image .left")
//            rotationAngle = 90
//        }
//        else if orientation == .right {
//            print("rotating image .right")
//            rotationAngle = -90
//        }
//        else if orientation == .down {
//            print("rotating image .down")
//            rotationAngle = 180
//        }
//
//        print("hi")
//        print("size= \(self.size)")
//        UIGraphicsBeginImageContext(self.size)
//        let context = UIGraphicsGetCurrentContext()
//        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
//
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        return newImage
//
//    }
//}

class CustomUIAlertController: UIAlertController {
    var rotationAngle = 0.0
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle))
        
        // doesnt work in portrait mode?
        UIView.animate(withDuration: 0.25) {
            self.view.alpha = 0.9
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.view.isHidden = true
    }
}
