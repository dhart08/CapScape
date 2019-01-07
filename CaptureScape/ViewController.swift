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
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var slideshowButton: CustomButton!
    @IBOutlet weak var photoPreview: UIImageView!
    @IBOutlet weak var filesButton: UIButton!
    
    
// MARK: - APP Variables ------------------------------------------------------
    
    var locationManager: CLLocationManager!
    var locationFinder: LocationFinder!
    
    var directoryHandler: DirectoryHandler!
    
    var dropboxClient: DropboxClient! = nil
    
    var camera: Camera!
    var movieInput: MovieInput!
    var movieOutput: MovieOutput!
    var renderView: RenderView!
    var blendFilter: SourceOverBlend!
    var chromaFilter: ChromaKeying!
    var coordinatesOverlay: PictureInput!
    var pictureOutput: PictureOutput!
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

// MARK: - ViewController Methods ---------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveCoordinates(_:)), name: .didReceiveCoordinates, object: nil)
        
        locationFinder = LocationFinder()
        locationFinder.requestAuthorization()
        
        directoryHandler = DirectoryHandler()
        directoryHandler.changeDirectory(dirType: .appDocuments, url: nil)
        
        updateCoordinatesOverlay(latitude: "Waiting...", longitude: "Waiting...")
        
        do {
            camera = try Camera(sessionPreset: .hd1920x1080, cameraDevice: getCaptureDevice(), location: .backFacing, captureAsYUV: true)
            
            renderView = RenderView(frame: cameraView.bounds)
            renderView.fillMode = .stretch
            cameraView.addSubview(renderView)
            cameraView.bringSubview(toFront: mapView)
            cameraView.bringSubview(toFront: filesButton)
            
            blendFilter = SourceOverBlend()
            chromaFilter = ChromaKeying()
            chromaFilter.colorToReplace = Color.green
            
            camera --> blendFilter
            coordinatesOverlay --> chromaFilter --> blendFilter --> renderView
            
            coordinatesOverlay.processImage()
            //camera.startCapture()
        }
        catch {
            popupMessage(message: "Could not get camera started in ViewDidLoad")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
            
            self.blendFilter --> self.movieOutput
            
            self.camera.audioEncodingTarget = self.movieOutput
            
            self.movieOutput.startRecording()
            }
        }
        else {
            isVideoRecording = false
            
            movieOutput.finishRecording() {
                self.camera.audioEncodingTarget = nil
                self.movieOutput = nil
                
                self.popupMessage(message: "Video Saved")
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
//        pictureOutput = PictureOutput()
//        pictureOutput.encodedImageFormat = .png
//        pictureOutput.imageAvailableCallback = { outputImage in
//
//            DispatchQueue.global().async {
//                self.directoryHandler.createDirectory(dirType: .photos)
//
//                let outputPNG = UIImagePNGRepresentation(outputImage)
//                let fileURL = URL(fileURLWithPath: "Photos/\(self.createTimestamp()).png", relativeTo: self.directoryHandler.getDocumentsPath())
//
//                try! outputPNG?.write(to: fileURL)
//            }
//
//            DispatchQueue.main.async {
//                self.photoPreview.image = outputImage
//                self.lastPictureImage = outputImage
//
//                self.pictureOutput = nil
//
//                if self.isVideoRecording == true {
//                    self.updateSlideshowImage()
//                }
//
//                self.flashScreen()
//            }
//
//        }
//
//        blendFilter --> pictureOutput
        

        self.takePhoto { (image) in
            DispatchQueue.main.async {
                self.flashScreen()
                self.photoPreview.image = image
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
            
//            let blackRect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
//            UIGraphicsBeginImageContext(blackRect.size)
//            UIColor.black.setFill()
//            UIRectFill(blackRect)
//
//            currentSlideshowInput = PictureInput(image: UIGraphicsGetImageFromCurrentImageContext()!)
//            UIGraphicsEndImageContext()
            
            
            flashScreen()

            self.takePhoto(completion: { (image) in
                DispatchQueue.main.async {
                    //self.flashScreen()
                    self.photoPreview.image = image

                    self.lastPictureImage = image

                    self.currentSlideshowInput = PictureInput(image: self.lastPictureImage)

                    self.slideShowBlendFilter = SourceOverBlend()

                    self.directoryHandler.createDirectory(dirType: .slideshows)
                    self.fileURL = URL(fileURLWithPath: "Slideshows/\(self.createTimestamp()).m4a", relativeTo: self.directoryHandler.getDocumentsPath())

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
                
                UISaveVideoAtPathToSavedPhotosAlbum(self.fileURL.path, nil, nil, nil)
                
                self.popupMessage(message: "Slideshow Saved")
                //self.flashScreen()
            }

            self.slideshowButton.setImage(UIImage(named: "audio_start"), for: .normal)
            self.videoButton.setImage(UIImage(named: "video_start"), for: .normal)
            self.videoButton.isEnabled = true
        }
        
    }
    
    @IBAction func filesButtonClick(_ sender: UIButton) {
        let fileListController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FileListController") as? FileListController
        
        fileListController?.passClientToMainView = { client in
            print("Dropbox client passed back to MainView")
            self.dropboxClient = client
        }
        
        if let dropboxClient = dropboxClient {
            fileListController?.dropboxClient = dropboxClient
        }
        
        present(fileListController!, animated: true, completion: nil)
    }
    
    @IBAction func mapViewClick(_ sender: Any) {
        if isMapFullScreen == false {
            photoPreview.isHidden = true
            
            mapViewFrame = mapView.frame
            mapView.userTrackingMode = .none
            
            closeMapButton = UIButton(type: .roundedRect)
            closeMapButton.frame = CGRect(x: UIScreen.main.bounds.width - 100,
                                          y: UIScreen.main.bounds.height - 50,
                                          width: 100,
                                          height: 50)
            closeMapButton.layer.cornerRadius = 10
            
            closeMapButton.backgroundColor = UIColor.white
            closeMapButton.alpha = 0.5
            closeMapButton.setTitle("Close", for: .normal)
            closeMapButton.addTarget(self, action: #selector(ViewController.closeMapButtonClick), for: .touchUpInside)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.mapView.frame = UIScreen.main.bounds
            }, completion: { _ in
                self.view.addSubview(self.closeMapButton)
            })
        }
        
        isMapFullScreen = true
    }
    
    @objc func closeMapButtonClick() {
        print("closeMapButton Clicked!")
        
        closeMapButton.removeFromSuperview()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.mapView.frame = self.mapViewFrame
        }) { (Bool) in
            self.photoPreview.isHidden = false
        }
        
        mapView.userTrackingMode = .follow
        
        isMapFullScreen = false
    }

// MARK: - Push Notifications ----------------------------------------------------
    
    @objc func onDeviceRotation() {
        if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            //videoCapture.setVideoOrientation(orientation: AVCaptureVideoOrientation.portrait)
            print("orientation: portrait")
            
            renderView.frame = cameraView.bounds
        }
        else if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            //videoCapture.setVideoOrientation(orientation: AVCaptureVideoOrientation.landscapeRight)
            print("orientation: landscape")
            
            renderView.frame = cameraView.bounds
            
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
                //renderView.orientation = .landscapeLeft
            }
            else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                //renderView.orientation = .landscapeRight
            }
        }
        
    }
    
    @objc func onDidReceiveCoordinates(_ notification: Notification) {
        let latitude: NSString!
        let longitude: NSString!
        
        if locationFinder!.latitude == nil || locationFinder.longitude == nil {
            return
        }
        
        let (latDeg, latMin, latSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.latitude!)
        latitude = NSString(string: " Lat: \(latDeg) \(latMin)' \(latSec)''")
        
        let (lonDeg, lonMin, lonSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.longitude!)
        longitude = NSString(string: " Lon: \(lonDeg) \(lonMin)' \(lonSec)''")
        
        updateCoordinatesOverlay(latitude: latitude, longitude: longitude)
        chromaFilter.removeSourceAtIndex(0)
        coordinatesOverlay.addTarget(chromaFilter)
        coordinatesOverlay.processImage()
        
        updateMap()
    }
    
// MARK: - UI Updating -----------------------------------------------------------
    
    func updateCoordinatesOverlay(latitude: NSString, longitude: NSString) {
        let greenRect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        UIGraphicsBeginImageContext(greenRect.size)
        UIColor.green.setFill()
        UIRectFill(greenRect)
        
        let blackRect = CGRect(
            x: 0,
            y: greenRect.height - (greenRect.height / 14),
            width: greenRect.width / 1.75,
            height: greenRect.height / 14
        )
        
        let rectClipPath = UIBezierPath(roundedRect: blackRect, byRoundingCorners: .topRight, cornerRadii: CGSize(width: 20, height: 20)).cgPath
        
        UIGraphicsGetCurrentContext()?.addPath(rectClipPath)
        UIGraphicsGetCurrentContext()?.setFillColor(UIColor.black.cgColor)
        UIGraphicsGetCurrentContext()?.closePath()
        UIGraphicsGetCurrentContext()?.fillPath()
        
        
        let fontAttrs = [
            NSAttributedString.Key.font: UIFont(name: "Futura", size: 22),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        
        
        latitude.draw(at: blackRect.origin, withAttributes: fontAttrs as [NSAttributedString.Key : Any])
        longitude.draw(at: CGPoint(x: blackRect.origin.x, y: blackRect.origin.y + 25), withAttributes: fontAttrs as [NSAttributedString.Key : Any])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        coordinatesOverlay = PictureInput(image: image!)
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
    
    func getCaptureDevice() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
            
            if device.isSmoothAutoFocusSupported == true {
                try! device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            }
            
            return device
        }
        else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            
            if device.isSmoothAutoFocusSupported == true {
                try! device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            }
            
            return device
        }
        else {
            popupMessage(message: "getCaptureDevice() could not get a device!")
            fatalError("ERROR: Could not get capture device!")
        }
        
    }
    
    func popupMessage(message: String) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        present(alert, animated: true) {
            usleep(1000 * 500)
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
    func createTimestamp() -> String {
        let timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "HHmmssMMddyyyy"
        
        let timestamp = timestampFormatter.string(from: Date())
        
        return timestamp
    }
    
    func takePhoto(completion: @escaping (UIImage) -> Void) {
        self.pictureOutput = PictureOutput()
        self.pictureOutput.encodedImageFormat = .png
        self.pictureOutput.imageAvailableCallback = { outputImage in
            print("imageCallBack called!")
            
            //DispatchQueue.main.async {
                completion(outputImage)
            //}
        
            self.directoryHandler.createDirectory(dirType: .photos)
            
            let outputPNG = UIImagePNGRepresentation(outputImage)
            let fileURL = URL(fileURLWithPath: "Photos/\(self.createTimestamp()).png", relativeTo: self.directoryHandler.getDocumentsPath())
            
            try! outputPNG?.write(to: fileURL)
            
            self.pictureOutput = nil
            
            print("image saved!")

        }
        
        self.blendFilter --> self.pictureOutput
    }
}

extension ViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        print("audioRecroder delegate called!")
        UISaveVideoAtPathToSavedPhotosAlbum(fileURL.path, nil, nil, nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("ERROR: Audio recorder experienced error in encoding!!!!!!!!")
    }
}

extension ViewController: MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        popupMessage(message: "Map was loaded!")
    }
}
