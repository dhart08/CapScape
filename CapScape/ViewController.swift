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
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    let videoCapture = VideoCapture()
    
    let photoCapture = PhotoCapture()
    var currentPhoto: UIImage?
    
    var timer: Timer!
    var locationManager: CLLocationManager!
    var locationFinder: LocationFinder!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        let worker1 = DispatchQueue(label: "worker1")
//        let worker2 = DispatchQueue(label: "worker2")
//
//        worker1.async {
//            //code here
//        }
//        worker2.async {
//            //code here
//        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveImage(_:)), name: .didReceiveImage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveCoordinates(_:)), name: .didReceiveCoordinates, object: nil)
        
        videoCapture.setupSession()
        videoCapture.setVideoPreviewInView(previewView: cameraView)
        
        photoCapture.setupSession()
        
        locationFinder = LocationFinder()
        locationFinder.requestAuthorization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        videoCapture.startRunningSession()
        
        cameraView.bringSubview(toFront: recordButton)
        cameraView.bringSubview(toFront: snapshotButton)
        
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
        photoCapture.takePhoto()
    }
    
    @objc func onDidReceiveImage(_ notification: Notification) {
        currentPhoto = photoCapture.getPhoto()
        imageView.image = currentPhoto
    }
    
    @objc func onDidReceiveCoordinates(_ notification: Notification) {
        let (latDeg, latMin, latSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.latitude)
        let (lonDeg, lonMin, lonSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.longitude)
        
        latitudeLabel.text = "\(latDeg) \(latMin)' \(latSec)''"
        longitudeLabel.text = "\(lonDeg) \(lonMin)' \(lonSec)''"
    }
    
}

