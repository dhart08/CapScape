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
    //@IBOutlet weak var photoPreview: UIImageView!
    @IBOutlet weak var filesButton: UIButton!
    @IBOutlet weak var zoomLabel: UILabel!
    
    @IBOutlet weak var splashScreenContainer: UIView!
    @IBOutlet weak var landscapeImage: UIImageView!
    @IBOutlet weak var appNameImage: UIImageView!
    
// MARK: - APP Variables ------------------------------------------------------
    
    var locationManager: CLLocationManager!
    var locationFinder: LocationFinder!
    
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
    var compassNeedlePictureInput: PictureInput!
    var pictureOutput: PictureOutput!
    var imageOrientation: UIImageOrientation!
    var videoOrientation: CGFloat!
    var lastPictureImage: UIImage!
    var audioRecorder: AVAudioRecorder!
    var currentSlideshowInput: PictureInput!
    var slideShowBlendFilter: SourceOverBlend!
    var slideshowMovieOutput: MovieOutput!
    
    var isVideoRecording: Bool = false
    var isAudioRecording: Bool = false
    var fileURL: URL!
    
    var isMapFullScreen: Bool = false
    var mapViewFrame: CGRect!
    var closeMapButton: UIButton!
    
    var lastZoomFactor: CGFloat = 1.0

// MARK: - ViewController Methods ---------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        animateSplashScreen()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveCoordinates(_:)), name: .didReceiveCoordinates, object: nil)
        
        locationFinder = LocationFinder()
        locationFinder.requestAuthorization()
        
        directoryHandler = DirectoryHandler()
        directoryHandler.changeDirectory(dirType: .appDocuments, url: nil)
        
        updateCoordinatesOverlay(latitude: "Waiting...", longitude: "Waiting...", cardinalDirection: "NA")
        
        //DispatchQueue.global().async {
        
            setCameraDevice()

            renderView = RenderView(frame: cameraView.bounds)
            renderView.fillMode = .stretch
            cameraView.addSubview(renderView)
            cameraView.bringSubview(toFront: mapView)
            cameraView.bringSubview(toFront: filesButton)

            cameraOverlayBlendFilter = SourceOverBlend()
            //overlayBlender = SourceOverBlend()
            //cameraBlender = SourceOverBlend()
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
//            self.cameraView.bringSubview(toFront: self.mapView)
//            self.cameraView.bringSubview(toFront: self.filesButton)
//
//            self.blendFilter = SourceOverBlend()
//            self.chromaFilter = ChromaKeying()
//            self.chromaFilter.colorToReplace = Color.green
//
//            self.camera --> self.blendFilter
//            self.coordinatesOverlay --> self.chromaFilter --> self.blendFilter --> self.renderView
//
//            self.coordinatesOverlay.processImage()
//
//            self.camera.startCapture()
//
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("ViewController: viewWillAppear")
        NotificationCenter.default.addObserver(self, selector: #selector(onDeviceRotation), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        locationFinder.startFindingLocation()
        camera.startCapture()
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
            
            sender.setImage(UIImage(named: "video_stop"), for: .normal)
            photoButton.setImage(UIImage(named: "photo_disabled"), for: .normal)
            photoButton.isEnabled = false
            slideshowButton.setImage(UIImage(named: "audio_disabled"), for: .normal)
            slideshowButton.isEnabled = false
            
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
                
                self.popupMessage(message: "Video Saved", duration: 500)
                //self.flashScreen()
            }
            
            videoButton.setImage(UIImage(named: "video_start"), for: .normal)
            photoButton.setImage(UIImage(named: "photo_start"), for: .normal)
            photoButton.isEnabled = true
            slideshowButton.setImage(UIImage(named: "audio_start"), for: .normal)
            slideshowButton.isEnabled = true
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
            
            slideshowButton.setImage(UIImage(named: "audio_stop"), for: .normal)
            videoButton.setImage(UIImage(named: "video_disabled"), for: .normal)
            videoButton.isEnabled = false
            
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
                
                self.popupMessage(message: "Slideshow Saved", duration: 500)
                //self.flashScreen()
            }

            self.slideshowButton.setImage(UIImage(named: "audio_start"), for: .normal)
            self.videoButton.setImage(UIImage(named: "video_start"), for: .normal)
            self.videoButton.isEnabled = true
        }
        
    }
    
    @IBAction func filesButtonClick(_ sender: UIButton) {
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
        
        let myDocumentsList = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        var myDocumentsDir = myDocumentsList[0]
        print(myDocumentsDir)

        let pickerController = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        pickerController.allowsMultipleSelection = true
        pickerController.delegate = self

        present(pickerController, animated: true, completion: nil)
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
    
    // MARK: - Push Notifications ----------------------------------------------------
    
    @objc func onDeviceRotation() {
        if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            if UIDevice.current.orientation == UIDeviceOrientation.portrait {
                imageOrientation = UIImageOrientation.up
                videoOrientation = CGFloat(0)
                print("orientation: portrait up")
            }
            else if UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown {
                imageOrientation = UIImageOrientation.down
                videoOrientation = CGFloat(-Double.pi)
                print("orientation portrait down")
            }
        }
        else if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
                imageOrientation = UIImageOrientation.left
                videoOrientation = CGFloat(Double.pi / -2)
                print("orientation: landscape left")
            }
            else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                imageOrientation = UIImageOrientation.right
                videoOrientation = CGFloat(Double.pi / 2)
                print("orientation: landscape right")
            }
        }
        
    }
    
    @objc func onDidReceiveCoordinates(_ notification: Notification) {
        
        if locationFinder!.latitude == nil || locationFinder.longitude == nil {
            return
        }
        
        let (dmsLatitude, dmsLongitude) = locationFinder.decimalToDMSString(latitude: locationFinder.latitude, longitude: locationFinder.longitude)
        
        updateCoordinatesOverlay(latitude: NSString(string: dmsLatitude), longitude: NSString(string: dmsLongitude), cardinalDirection: locationFinder.getCardinalDirection())
        
//        overlayBlender.removeSourceAtIndex(0)
//        compassNeedlePictureInput.addTarget(overlayBlender)
//        compassNeedlePictureInput.processImage()
        
        chromaFilter.removeSourceAtIndex(0)
        coordinatesOverlay.addTarget(chromaFilter)
        coordinatesOverlay.processImage()
        
        print("heading: \(locationFinder.getCardinalDirection())")
        
        updateMap()
    }
    
// MARK: - UI Updating -----------------------------------------------------------
    
    func updateCoordinatesOverlay(latitude: NSString, longitude: NSString, cardinalDirection: String!) {
        let screenWidth: CGFloat = UIScreen.main.bounds.width
        let screenHeight: CGFloat = UIScreen.main.bounds.height
        
        var context: CGContext!
        
        var overlayRect: CGRect!
        var overlayOrigin: CGPoint!
        var overlayRotation: CGFloat = 0
        var overlayWidth: CGFloat!
        var overlayHeight: CGFloat!
        
        let leftRotationAngle: CGFloat = CGFloat(90 * Double.pi / 180)
        let rightRotationAngle: CGFloat = CGFloat(-90 * Double.pi / 180)
        
        var coordinatesBoxRatio: [String: CGFloat] = ["width": 0.0, "height": 0.0]
        var directionBoxRatio: [String: CGFloat] = ["width": 0.0, "height": 0.0]
        
        print("screen width change: ", UIScreen.main.bounds.width, "     screen height change: ", UIScreen.main.bounds.height)

        // get phone orientation screen measurements
        // set landscape mode sizes/ratios
        if (imageOrientation == UIImageOrientation.left) || (imageOrientation == UIImageOrientation.right) {
            if imageOrientation == UIImageOrientation.left {
                print("overlayOrigin on left")
                overlayOrigin = CGPoint(x: screenWidth, y: 0)
            }
            else if imageOrientation == UIImageOrientation.right {
                print("overlayOrigin on right")
                overlayOrigin = CGPoint(x: 0, y: screenHeight)
            }

            overlayWidth = screenHeight
            overlayHeight = screenWidth
            
            coordinatesBoxRatio["width"] = 0.3
            coordinatesBoxRatio["height"] = 0.25
            
            directionBoxRatio["width"] = 0.125
            directionBoxRatio["height"] = 0.15

            //overlayRotation = (imageOrientation == UIImageOrientation.left) ? leftRotationAngle : rightRotationAngle
            
            if imageOrientation == UIImageOrientation.left {
                overlayRotation = leftRotationAngle
            }
            else {
                overlayRotation = rightRotationAngle
            }
        }
        // set portrait mode sizes/ratios
        else {
            overlayOrigin = CGPoint(x: 0, y: 0)

            overlayWidth = screenWidth
            overlayHeight = screenHeight
            
            coordinatesBoxRatio["width"] = 0.55
            coordinatesBoxRatio["height"] = 0.15
            
            directionBoxRatio["width"] = 0.20
            directionBoxRatio["height"] = 0.075
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
        context.closePath()
        context.fillPath()
        
//        //create black rectangle for direction black box
//        let directionBlackRect = CGRect(
//            x: overlayWidth - (overlayWidth * directionBoxRatio["width"]!),
//            y: overlayHeight - (overlayHeight * directionBoxRatio["height"]!),
//            width: overlayWidth * directionBoxRatio["width"]!,
//            height: overlayHeight * directionBoxRatio["height"]!
//        )
//        // curve edges of direction black box
//        let directionBlackRectClipPath = UIBezierPath(roundedRect: directionBlackRect, byRoundingCorners: .topLeft, cornerRadii: CGSize(width: 20, height: 20)).cgPath
//        // draw direction black box on bitmap
//        context.addPath(directionBlackRectClipPath)
//        context.setFillColor(UIColor.black.cgColor)
//        context.closePath()
//        context.fillPath()
        
        //set font for on-screen coordinates stamp
        let coordinateFontAttrs = [
            NSAttributedString.Key.font: UIFont(name: "Futura", size: 22),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        //draw coordinates on bitmap
        latitude.draw(at:CGPoint(x: coordinatesBlackRect.origin.x + 5, y: coordinatesBlackRect.origin.y), withAttributes: coordinateFontAttrs as [NSAttributedString.Key : Any])
        longitude.draw(at: CGPoint(x: coordinatesBlackRect.origin.x + 5, y: coordinatesBlackRect.origin.y + 25), withAttributes: coordinateFontAttrs as [NSAttributedString.Key : Any])
        "Heading: \(cardinalDirection!)".draw(at: CGPoint(x: coordinatesBlackRect.origin.x + 5 , y: coordinatesBlackRect.origin.y + 50), withAttributes: coordinateFontAttrs as [NSAttributedStringKey : Any])
        
        // create time formatter for on-screen timestamp
        let timeStampFormatter = DateFormatter()
        timeStampFormatter.dateFormat = "M/dd/yyyy, h:mm:ss a"
        let timestamp = timeStampFormatter.string(from: Date())
        
        // set font for on-screen timestamp
        let timestampFontAttrs = [
            NSAttributedString.Key.font: UIFont(name: "Futura", size: 16),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        // draw timestamp on bitmap
        "\(timestamp)".draw(at: CGPoint(x: coordinatesBlackRect.origin.x + 5, y: coordinatesBlackRect.origin.y + 80), withAttributes: timestampFontAttrs as [NSAttributedString.Key : Any])
        
        //set font for on-screen cardinal direction stamp
//        let directionFontAttr = [
//            NSAttributedString.Key.font: UIFont(name: "Futura", size: 32),
//            NSAttributedString.Key.foregroundColor: UIColor.white
//        ]

        // draw cardinal direction on bitmap
//        let direction = NSString(string: cardinalDirection)
//        let directionCGPoint = CGPoint(x: directionBlackRect.origin.x + 15, y: directionBlackRect.origin.y + 15)
//        direction.draw(at: directionCGPoint, withAttributes: directionFontAttr as [NSAttributedString.Key : Any])
        
        //draw red rectangle
//        context.setFillColor(UIColor.red.cgColor)
//        let rect = CGRect(x: 0, y: 0, width: overlayWidth/2, height: overlayHeight/2)
//        context.addRect(rect)
//        context.drawPath(using: .fillStroke)
//
//        //draw blue circle
//        let center = CGPoint(x: overlayWidth/2, y: overlayHeight/2)
//        let radius = CGFloat(100)
//        context.setFillColor(UIColor.blue.cgColor)
//        context.addArc(center: center, radius: radius, startAngle: CGFloat(0), endAngle: CGFloat(Double.pi*2), clockwise: true)
//        context.drawPath(using: .fillStroke)
        
/////////////////////////////////////////////////////////////////////////////////
        
//        let renderer = UIGraphicsImageRenderer(size: CGSize(width: overlayWidth, height: overlayHeight))
//        let overlayImage = renderer.image { imageContext in
//            imageContext.cgContext.translateBy(x: overlayOrigin.x, y: overlayOrigin.y)
//            imageContext.cgContext.rotate(by: overlayRotation)
//
//            overlayRect = CGRect(x: 0, y: 0, width: overlayWidth/1.5, height: overlayHeight/1.5)
//
//            imageContext.cgContext.setFillColor(UIColor.purple.cgColor)
//            imageContext.cgContext.setStrokeColor(UIColor.purple.cgColor)
//            imageContext.cgContext.addRect(overlayRect)
//            imageContext.cgContext.drawPath(using: .fillStroke)
        
//            // create black rectangle for overlay
//            let blackRect = CGRect(
//                x: 0,
//                y: overlayHeight - (overlayHeight / 9),
//                width: overlayWidth / 1.7,
//                height: overlayHeight / 9
//            )
//
//            // curve edges of black rectangle
//            let rectClipPath = UIBezierPath(roundedRect: blackRect, byRoundingCorners: .topRight, cornerRadii: CGSize(width: 20, height: 20)).cgPath
//
//            // draw black rectangle on bitmap
//            imageContext.cgContext.addPath(rectClipPath)
//            imageContext.cgContext.setFillColor(UIColor.black.cgColor)
//            imageContext.cgContext.closePath()
//            imageContext.cgContext.fillPath()
//        }
        
        
    

//        // create overlay rectangle
//        overlayRect = CGRect(x: 0, y: 0, width: overlayWidth, height: overlayHeight)
//        print ("overlayRect.width: ", overlayRect.size.width, "     overlayRect.height: ", overlayRect.size.height)
//        print("current screen width: ", UIScreen.main.bounds.width, "     current screen height: ", UIScreen.main.bounds.height)
        
        // create graphics context
        //UIGraphicsBeginImageContext(CGSize(width: screenWidth, height: screenHeight))
//        UIGraphicsBeginImageContext(UIScreen.main.bounds.size)
//        context = UIGraphicsGetCurrentContext()
//        print("UIGraphicsContext width: ", context.width, "     UIGraphicsContext height: ", context.height)
//
//        let smokeScreen = CGRect(x: 0, y: 0, width: context.width, height: context.height)
//        context.setFillColor(UIColor.gray.cgColor)
//        context.setStrokeColor(UIColor.gray.cgColor)
//        context.setAlpha(CGFloat(0.5))
//        context.addRect(smokeScreen)
//        context.drawPath(using: .fillStroke)
//
//        overlayImage.draw(at: CGPoint(x: 0, y: 0))
//        print("origin width: ", overlayWidth, "     overlayHeight: ", overlayHeight)
    
        
        
        // shift graphics context and rotate origin
        //context.rotate(by: overlayRotation)
        //context.translateBy(x: overlayOrigin.x, y: overlayOrigin.y)
        
        
        // draw green screen on bitmap
        //let greenRect = CGRect(x: 0, y: 0, width: overlayWidth, height: overlayHeight)
        //let greenRect = CGRect(x: 0, y: 0, width: 100, height: 200)
        //UIColor.purple.setFill()
        //UIRectFill(greenRect)
        //context.setFillColor(UIColor.purple.cgColor)
        //context.addRect(greenRect)
        //context.drawPath(using: .fillStroke)
        
//        // create black rectangle for overlay
//        let blackRect = CGRect(
//            x: 0,
//            y: overlayHeight - (overlayHeight / 9),
//            width: overlayWidth / 1.7,
//            height: overlayHeight / 9
//        )
//
//        // curve edges of black rectangle
//        let rectClipPath = UIBezierPath(roundedRect: blackRect, byRoundingCorners: .topRight, cornerRadii: CGSize(width: 20, height: 20)).cgPath
//
//        // draw black rectangle on bitmap
//        UIGraphicsGetCurrentContext()?.addPath(rectClipPath)
//        UIGraphicsGetCurrentContext()?.setFillColor(UIColor.black.cgColor)
//        UIGraphicsGetCurrentContext()?.closePath()
//        UIGraphicsGetCurrentContext()?.fillPath()
//
//        // create time formatter for on-screen timestamp
//        let timeStampFormatter = DateFormatter()
//        timeStampFormatter.dateFormat = "M/dd/yyyy, h:mm:ss a"
//        let timestamp = timeStampFormatter.string(from: Date())
//
//        // set font for on-screen coordinates stamp
//        let coordinateFontAttrs = [
//            NSAttributedString.Key.font: UIFont(name: "Futura", size: 22),
//            NSAttributedString.Key.foregroundColor: UIColor.white
//        ]
//
//        // draw coordinates on bitmap
//        latitude.draw(at: blackRect.origin, withAttributes: coordinateFontAttrs as [NSAttributedString.Key : Any])
//        longitude.draw(at: CGPoint(x: blackRect.origin.x, y: blackRect.origin.y + 25), withAttributes: coordinateFontAttrs as [NSAttributedString.Key : Any])
//
//        // set font for on-screen timestamp
//        let timestampFontAttrs = [
//            NSAttributedString.Key.font: UIFont(name: "Futura", size: 16),
//            NSAttributedString.Key.foregroundColor: UIColor.white
//        ]
//
//        // draw timestamp on bitmap
//        "  \(timestamp)".draw(at: CGPoint(x: blackRect.origin.x, y: blackRect.origin.y + 52), withAttributes: timestampFontAttrs as [NSAttributedString.Key : Any])
//
//        //set font for on-screen cardinal direction stamp
//        let directionFontAttr = [
//            NSAttributedString.Key.font: UIFont(name: "Futura", size: 32),
//            NSAttributedString.Key.foregroundColor: UIColor.white
//        ]
//
//        // draw cardinal direction on bitmap
//        let direction = NSString(string: cardinalDirection)
//        let directionCGPoint = CGPoint(x: greenRect.origin.x + 25, y: greenRect.origin.y + 25)
//        direction.draw(at: directionCGPoint, withAttributes: directionFontAttr as [NSAttributedString.Key : Any])
        
        // get bitmap from the image context
        let coordinatesImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        coordinatesOverlay = PictureInput(image: coordinatesImage!)
        
        /////////////////////////////////////////////////////////////////////////////////////////////////
        
//        let divider: CGFloat = 4
//        let compassInputImage = UIImage(named: "compass_needle")
//        let compassInputImageRatio = CGFloat((compassInputImage?.size.width)!) / CGFloat((compassInputImage?.size.height)!)
//        let compassImageNewSize = CGSize(width: screenHeight / divider * compassInputImageRatio, height: screenHeight / divider)
//        let compassImageRect = CGRect(origin: CGPoint(x: 100, y: 100), size: compassImageNewSize)
//        //let compassImageRect = CGRect(x: 0, y: 0, width: screenHeight / divider * compassInputImageRatio, height: screenHeight / divider)
//        //let compassOrigin = CGPoint(x: screenHeight / divider * compassInputImageRatio / 2, y: screenHeight / divider / 2)
//
//        UIGraphicsBeginImageContext((compassInputImage?.size)!)
//
//        let context = UIGraphicsGetCurrentContext()
//
//        context?.rotate(by: CGFloat(locationFinder.heading * Double.pi / 180))
//        context?.translateBy(x: compassImageRect.origin.x, y: compassImageRect.origin.y)
//        //context?.translateBy(x: compassImageRect.size.width * 0.5, y: compassImageRect.size.height * 0.5)
        
        
//-------> start here!
        //"\(locationFinder.heading!)".dr
        
        
        //compassInputImage?.draw(in: compassImageRect)


        //let compassOutputImage = UIGraphicsGetImageFromCurrentImageContext()
        //UIGraphicsEndImageContext()

        //compassNeedlePictureInput = PictureInput(image: compassOutputImage!)
        
        
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
                popupMessage(message: "setCameraObject: Could not create camera object.", duration: nil)
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
            popupMessage(message: "setCameraDevice() could not get a device!", duration: nil)
            fatalError("ERROR: Could not get capture device!")
        }
        
    }
    
    func popupMessage(message: String, duration: Int?) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        
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
        self.pictureOutput.encodedImageFormat = .jpeg
        self.pictureOutput.imageAvailableCallback = { outputImage in
            
            //set orientation of the output image
            let image = UIImage(cgImage: outputImage.cgImage!, scale: 1.0, orientation: self.imageOrientation)
            
            //DispatchQueue.main.async {
                completion(outputImage)
            //}
        
            self.directoryHandler.createDirectory(dirType: .photos)
            let fileURL = URL(fileURLWithPath: "Photos/\(self.createTimestamp()).jpg", relativeTo: self.directoryHandler.getDocumentsPath())
            
            let jpg = UIImageJPEGRepresentation(image, 1.0)
            try! jpg?.write(to: fileURL)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/dd/yyyy, h:mm:ss a"
            dateFormatter.timeZone = TimeZone.current
            let fileCreationDate = dateFormatter.string(from: Date())
            
            let exifParams = EXIFDataParams(latitude: self.locationFinder.latitude, longitude: self.locationFinder.longitude, creationDateTime: fileCreationDate, comment: "")
            
            let exifDataRaderWriter = EXIFDataReaderWriter()
            exifDataRaderWriter.writeEXIFDataToPhoto(fileURL: fileURL, image: jpg!, exifDataParams: exifParams)
            
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
        
        UIView.animate(withDuration: 0.75, delay: 0.5, usingSpringWithDamping: 0.5, initialSpringVelocity: 30, options: .curveEaseOut, animations: {
            self.appNameImage.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: { _ in
            DispatchQueue.global().async {
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
        popupMessage(message: "Map was loaded!", duration: 500)
    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {

        let ac = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        present(ac, animated: true, completion: nil)
        
    }
}

//extension UIImage {
//    func rotateImage(image: UIImage, degrees: CGFloat) -> UIImage {
//
//    }
//}
