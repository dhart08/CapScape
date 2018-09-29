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

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate{

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var snapshotButton: UIButton!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var latitudeValueLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var longitudeValueLabel: UILabel!
    @IBOutlet weak var photoPreview: UIImageView!
    
    let videoCapture = VideoCapture()
    
    let photoCapture = PhotoCapture()
    var currentPhoto: UIImage?
    
    var timer: Timer!
    var locationManager: CLLocationManager!
    var locationFinder: LocationFinder!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveImage(_:)), name: .didReceiveImage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveCoordinates(_:)), name: .didReceiveCoordinates, object: nil)
        
        videoCapture.setupSession()
        videoCapture.setVideoPreviewInView(previewView: cameraView)
        
        photoCapture.setupSession()
        
        locationFinder = LocationFinder()
        locationFinder.requestAuthorization()
        
        let photoPreviewTapGesture = UITapGestureRecognizer(target: self, action:#selector(photoViewSegue))
        photoPreview.addGestureRecognizer(photoPreviewTapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        videoCapture.startRunningSession()
        
        cameraView.bringSubview(toFront: recordButton)
        cameraView.bringSubview(toFront: snapshotButton)
        cameraView.bringSubview(toFront: latitudeLabel)
        cameraView.bringSubview(toFront: latitudeValueLabel)
        cameraView.bringSubview(toFront: longitudeLabel)
        cameraView.bringSubview(toFront: longitudeValueLabel)
        cameraView.bringSubview(toFront: photoPreview)
        
        locationFinder.startFindingLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        videoCapture.stopRunningSession()
        locationFinder.stopFindingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func photoViewSegue(gesture: UIGestureRecognizer) {
        if (photoPreview == gesture.view as? UIImageView) {
            print("photoViewSegue")
        }
        else {
            print("not photoPreview")
        }
    }

    @IBAction func recordButtonClick(_ sender: UIButton) {
        if (sender.title(for: .normal) == "Record") {
            print("Record Clicked")
            sender.setTitle("Stop", for: .normal)
            sender.setTitleColor(UIColor.white, for: .normal)
        }
        else {
            print("Stop Clicked")
            sender.setTitle("Record", for: .normal)
            sender.setTitleColor(UIColor.red, for: .normal)
        }
    }
    
    @IBAction func snapshotButtonClick(_ sender: UIButton) {
        let photoThread = DispatchQueue(label: "photoThread")
        photoThread.async {
            self.photoCapture.takePhoto()
        }
    }
    
    @objc func onDidReceiveImage(_ notification: Notification) {
        currentPhoto = photoCapture.getPhoto()
        photoPreview.image = currentPhoto
        
        let minSize: CGSize = photoPreview.frame.size
        let minX: CGFloat = photoPreview.frame.origin.x
        let minY: CGFloat = photoPreview.frame.origin.y
        
        photoPreview.alpha = 0.0
        photoPreview.frame = CGRect(x: 0, y: 0, width: cameraView.frame.width, height: cameraView.frame.height)
        
        UIView.animate(withDuration: 0.2){
            self.photoPreview.alpha = 1
            self.photoPreview.frame.size = minSize
            self.photoPreview.frame.origin.x = minX
            self.photoPreview.frame.origin.y = minY
        }
    }
    
    @objc func onDidReceiveCoordinates(_ notification: Notification) {
        let (latDeg, latMin, latSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.latitude)
        let (lonDeg, lonMin, lonSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.longitude)
        
        latitudeValueLabel.text = "\(latDeg) \(latMin)' \(latSec)''"
        longitudeValueLabel.text = "\(lonDeg) \(lonMin)' \(lonSec)''"
    }
    
}

