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

class ViewController: UIViewController, CLLocationManagerDelegate, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var snapshotButton: UIButton!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    //helps transfer data between input devices (camera, mic, etc.) and a view
    var captureSession: AVCaptureSession?
    //helps render the camera view finder in the view controller
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var input: AVCaptureDeviceInput?
    
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
        
        //initialize a decive object and provide the video as a media type parameter object
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        //attaches the input device to the capture device
        do {
            input = try AVCaptureDeviceInput(device: captureDevice!)
        } catch {
            print(error)
        }
        
        //initialize the captureSession object
        captureSession = AVCaptureSession()
        //add the input device to our session
        captureSession?.addInput(input!)
        
        //create an AVCaptureVideoPreviewLayer from the session
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        //configure the layer to resize while maintaining original aspect ratio
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        //set preview layer frame to our video controller view bounds
        //videoPreviewLayer?.bounds = view.layer.bounds
        videoPreviewLayer?.frame.size = cameraView.frame.size
        //add the preview layer as a sublayer to our cameraView
        cameraView.layer.addSublayer(videoPreviewLayer!)
        
        //start the capture session
        captureSession?.startRunning()
        
        cameraView.bringSubview(toFront: recordButton)
        cameraView.bringSubview(toFront: snapshotButton)
        
        locationFinder = LocationFinder()
        locationFinder.requestAuthorization()
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
//        print("Snapshot Clicked")
//
//        var photoCaptureSession = AVCaptureSession()
//        photoCaptureSession.sessionPreset = .medium
//
//        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
//            else {
//                print("UNABLE TO ACCESS BACK CAMERA")
//                return
//        }
//
//        var stillImageInput: AVCaptureDeviceInput?
//        do {
//            stillImageInput = try AVCaptureDeviceInput(device: backCamera)
//        }
//        catch {
//            print("UNABLE TO INITIALIZE BACK CAMERA")
//        }
//
//        let stillImageOutput = AVCapturePhotoOutput()
//
//        if (photoCaptureSession.canAddInput(stillImageInput!) && photoCaptureSession.canAddOutput(stillImageOutput)) {
//            photoCaptureSession.addInput(stillImageInput!)
//            photoCaptureSession.addOutput(stillImageOutput)
//        }
//
//        photoCaptureSession.startRunning()
//
//        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
//        stillImageOutput.capturePhoto(with: settings, delegate: self)
        
        var captureSession2: AVCaptureSession? = AVCaptureSession()
        let captureDevice2 = AVCaptureDevice.default(for: AVMediaType.video)
        
        let input2: AVCaptureDeviceInput?
        do {
            input2 = try AVCaptureDeviceInput(device: captureDevice2!)
            captureSession2?.addInput(input2!)
        } catch {
            print("COULDN'T ASSIGN DEVICE INPUT TO VARIABLE")
            return
        }
        
        let photoOutput = AVCaptureVideoDataOutput()
        let queue = DispatchQueue(label: "com.davidhartzog.queue")
        photoOutput.setSampleBufferDelegate(self, queue: queue)
        if ((captureSession2?.canAddOutput(photoOutput))!) {
            captureSession2?.addOutput(photoOutput)
        }
        else {
            print("CANT ADD OUTPUT TO CAPTURESESSION")
        }
        
        captureSession2?.startRunning()
        captureSession2?.stopRunning()
        print("CAPTURESESSION2 STOPPED RUNNING")
    }
    
//    func setTheImage(image: UIImage) {
//        imageView.image = image
//    }
    
    func captureOutput(_ output: AVCaptureOutput,
                                didOutput sampleBuffer: CMSampleBuffer,
                                from connection: AVCaptureConnection) {
        //print("IMAGE RECEIVED!!!")
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let context: CIContext = CIContext.init()
        let cgImage: CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let image: UIImage = UIImage.init(cgImage: cgImage)
        
        //setTheImage(image: image)
        
        DispatchQueue.main.async { [weak self] in
            self?.imageView.image = image
        }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("trying to save photo...")
        
        guard let imageData = photo.fileDataRepresentation()
            else {
                return
        }
        DispatchQueue.main.async { [unowned self] in
            let image = UIImage(data: imageData)
            self.imageView.image = image
        }
        
        
        //UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        
        print("photo saved!")
    }
    
    
    
    func setupLocationManager() -> Void{
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        //todo: finish loading up anything that needs to be here in order to update the location using delegates
    }

    func getCoordinates() -> CLLocation! {
        //Check if the user is allowed authorization
        var location: CLLocation!
        if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedWhenInUse) {
            
            location = locationManager.location
            return location
        }
        
        return nil
    }
    
    @objc func updateCoordinates() {
        let (latDeg, latMin, latSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.latitude)
        let (lonDeg, lonMin, lonSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.longitude)
        
        latitudeLabel.text = "\(latDeg) \(latMin)' \(latSec)''"
        longitudeLabel.text = "\(lonDeg) \(lonMin)' \(lonSec)''"
    }

    @IBAction func buttonClick(_ sender: UIButton) {
        statusLabel.text = "Running"
        statusLabel.textColor = UIColor.green
        
        locationFinder.startFindingLocation {
            print("!!!!!!!!!!!!")
        }
        
        if ((timer == nil) || (timer.isValid == false)) {
            timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(updateCoordinates), userInfo: nil, repeats: true)
        }
    }
    
    @IBAction func stopTimer(_ sender: UIButton) {
        timer.invalidate()
        
        locationFinder.stopFindingLocation()
        
        statusLabel.text = "Stopped"
        statusLabel.textColor = UIColor.red
    }
    
}

