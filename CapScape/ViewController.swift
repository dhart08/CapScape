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

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate{

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var snapshotButton: UIButton!
    @IBOutlet weak var photoPreview: UIImageView!
    
    var locationManager: CLLocationManager!
    var locationFinder: LocationFinder!
    
    var camera: Camera!
    var movieInput: MovieInput!
    var movieOutput: MovieOutput!
    var renderView: RenderView!
    var blendFilter: SourceOverBlend!
    var chromaFilter: ChromaKeying!
    var coordinatesOverlay: PictureInput!
    
    var isRecording: Bool = false
    var fileURL: URL!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveImage(_:)), name: .didReceiveImage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveCoordinates(_:)), name: .didReceiveCoordinates, object: nil)
        
        locationFinder = LocationFinder()
        locationFinder.requestAuthorization()
        
        updateCoordinatesOverlay(latitude: "Waiting...", longitude: "Waiting...")
        
        camera = try! Camera(sessionPreset: .hd1920x1080, cameraDevice: getCaptureDevice(), location: .backFacing, captureAsYUV: true)
        //camera = try! Camera(sessionPreset: .hd1280x720)
        
        renderView = RenderView(frame: cameraView.bounds)
        cameraView.addSubview(renderView)
        cameraView.bringSubview(toFront: recordButton)
        cameraView.bringSubview(toFront: snapshotButton)
        
        blendFilter = SourceOverBlend()
        chromaFilter = ChromaKeying()
        chromaFilter.colorToReplace = Color.green
        
        camera --> blendFilter
        coordinatesOverlay --> chromaFilter --> blendFilter --> renderView
        
        coordinatesOverlay.processImage()
        camera.startCapture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(onDeviceRotation), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        locationFinder.startFindingLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        locationFinder.stopFindingLocation()
    }
    
    func updateCoordinatesOverlay(latitude: NSString, longitude: NSString) {
        let greenRect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        UIGraphicsBeginImageContext(greenRect.size)
        UIColor.green.setFill()
        UIRectFill(greenRect)
        
        let blackRect = CGRect(
            x: 0,
            y: greenRect.height - (greenRect.height / 11),
            width: greenRect.width / 1.5,
            height: greenRect.height / 11
        )
        UIColor.black.setFill()
        UIRectFill(blackRect)
        
        let fontAttrs = [
            NSAttributedString.Key.font: UIFont(name: "Helvetica", size: 25),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        
        
        latitude.draw(at: blackRect.origin, withAttributes: fontAttrs as [NSAttributedString.Key : Any])
        longitude.draw(at: CGPoint(x: blackRect.origin.x, y: blackRect.origin.y + 25), withAttributes: fontAttrs as [NSAttributedString.Key : Any])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        coordinatesOverlay = PictureInput(image: image!)
    }
    
    @objc func onDeviceRotation() {
        if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            //videoCapture.setVideoOrientation(orientation: AVCaptureVideoOrientation.portrait)
            
            print("orientation: portrait")
        }
        else if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            //videoCapture.setVideoOrientation(orientation: AVCaptureVideoOrientation.landscapeRight)
            print("orientation: landscape")
            
            renderView.frame = cameraView.bounds
            renderView.orientation = .landscapeRight
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getCaptureDevice() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
            return device
        }
        else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            return device
        }
        else {
            fatalError("ERROR: Could not get capture device!")
        }
    }
    
    @IBAction func photoViewSegue(gesture: UIGestureRecognizer) {
//        print("photoViewSegue!")
//        let destinationVC = self.storyboard?.instantiateViewController(withIdentifier: "PhotoEditViewController") as! PhotoEditViewController
//        destinationVC.image = currentPhoto
//        self.navigationController?.pushViewController(destinationVC, animated: true)
    }

    @IBAction func recordButtonClick(_ sender: UIButton) {
        if isRecording == false {
            isRecording = true
            
            sender.setTitle("Stop", for: .normal)
            sender.setTitleColor(UIColor.red, for: .normal)
            
            let documentsDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            fileURL = URL(string: "\(createTimestamp()).mp4", relativeTo: documentsDir)
            
            do {
                try FileManager.default.removeItem(at: fileURL!)
            }
            catch {
                
            }
            
            movieOutput = try!  MovieOutput(URL: fileURL!, size: Size(width: 1080, height: 1920), liveVideo: true)
            
            blendFilter --> movieOutput
            movieOutput.startRecording()
        }
        else {
            isRecording = false
            
            sender.setTitle("Record", for: .normal)
            sender.setTitleColor(UIColor.white, for: .normal)
            
            movieOutput.finishRecording() {
                self.camera.audioEncodingTarget = nil
                self.movieOutput = nil
                
                UISaveVideoAtPathToSavedPhotosAlbum(self.fileURL.path, nil, nil, nil)
                
                self.popupMessage(message: "Video Saved")
            }
        }
    }
    
    @IBAction func snapshotButtonClick(_ sender: UIButton) {
        let photoThread = DispatchQueue(label: "photoThread")
        photoThread.async {
            //self.photoCapture.takePhoto()
            //self.videoCapture.captureImage()
        }
    }
    
    @objc func onDidReceiveImage(_ notification: Notification) {
        //currentPhoto = videoCapture.image
//        DispatchQueue.main.async {
//            self.photoPreview.image = self.currentPhoto
//
//
//        let minSize: CGSize = self.photoPreview.frame.size
//        let minX: CGFloat = self.photoPreview.frame.origin.x
//        let minY: CGFloat = self.photoPreview.frame.origin.y
//
//        self.photoPreview.alpha = 0.0
//        self.photoPreview.frame = CGRect(x: 0, y: 0, width: self.cameraView.frame.width, height: self.cameraView.frame.height)
//
//        UIView.animate(withDuration: 0.2){
//            self.photoPreview.alpha = 1
//            self.photoPreview.frame.size = minSize
//            self.photoPreview.frame.origin.x = minX
//            self.photoPreview.frame.origin.y = minY
//        }
//        }
    }
    
    @objc func onDidReceiveCoordinates(_ notification: Notification) {
        let latitude: NSString!
        let longitude: NSString!
        
        guard locationFinder!.latitude != nil && locationFinder.longitude != nil else {
            return
        }
        
        let (latDeg, latMin, latSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.latitude!)
        latitude = NSString(string: "Lat: \(latDeg) \(latMin)' \(latSec)''")
        
        let (lonDeg, lonMin, lonSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.longitude!)
        longitude = NSString(string: "Lon: \(lonDeg) \(lonMin)' \(lonSec)''")
        
        updateCoordinatesOverlay(latitude: latitude, longitude: longitude)
        chromaFilter.removeSourceAtIndex(0)
        coordinatesOverlay.addTarget(chromaFilter)
        coordinatesOverlay.processImage()
    }
    
    func createTimestamp() -> String {
        let timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "HHmmssMMddyyyy"
        
        let timestamp = timestampFormatter.string(from: Date())
        
        return timestamp
    }
    
    func popupMessage(message: String) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        present(alert, animated: true) {
            usleep(1000 * 500)
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
    
}

