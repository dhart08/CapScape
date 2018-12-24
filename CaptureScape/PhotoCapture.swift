//
//  PhotoCapture.swift
//  CapScape
//
//  Created by David on 9/27/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

class PhotoCapture: NSObject, AVCapturePhotoCaptureDelegate {
    
    var capturePhotoSession: AVCaptureSession?
    var capturePhotoDevice: AVCaptureDevice?
    var photoInput: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
    var photoPreviewLayer: AVCaptureVideoPreviewLayer?
    var photoSettings: AVCapturePhotoSettings?
    var image: UIImage?
    
    var photoOutput2: AVCapturePhotoOutput?
    
    func setupSession() {
        capturePhotoSession = AVCaptureSession()
        capturePhotoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
        
        do {
            photoInput = try AVCaptureDeviceInput(device: capturePhotoDevice!)
            capturePhotoSession?.addInput(photoInput!)
        } catch {
            print("COULDN'T ASSIGN DEVICE INPUT TO VARIABLE")
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        if ((capturePhotoSession?.canAddOutput(photoOutput!))!) {
            capturePhotoSession?.addOutput(photoOutput!)
        }
        else {
            print("CANT ADD OUTPUT TO CAPTUREPHOTOSESSION")
            return
        }
        photoOutput!.isHighResolutionCaptureEnabled = true
        photoOutput!.isLivePhotoCaptureEnabled = photoOutput!.isLivePhotoCaptureSupported
        
        capturePhotoSession?.commitConfiguration()

        print("PHOTOSESSION IS SET UP")
    }
    
    func setPhotoPreviewInView(previewView: UIView) {
        //create an AVCaptureVideoPreviewLayer from the session
        photoPreviewLayer = AVCaptureVideoPreviewLayer(session: capturePhotoSession!)
        //configure the layer to resize while maintaining original aspect ratio
        photoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        //set preview layer frame to our video controller view bounds
        //videoPreviewLayer?.bounds = view.layer.bounds
        photoPreviewLayer?.frame.size = previewView.frame.size
        //add the preview layer as a sublayer to our cameraView
        previewView.layer.addSublayer(photoPreviewLayer!)
    }
    
    func takePhoto() {
        //capturePhotoSession?.startRunning()
        print("CAPTUREPHOTOSESSION STARTED RUNNING")
        
        photoSettings = AVCapturePhotoSettings()
        photoSettings!.isHighResolutionPhotoEnabled = true
        photoOutput!.capturePhoto(with: photoSettings!, delegate: self)
        
        //capturePhotoSession?.stopRunning()
        print("CAPTUREPHOTOSESSION STOPPED RUNNING")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("photoOutput!")
        
        guard let imageData = photo.fileDataRepresentation()
            else {
                print("FAILED TO GET IMAGE DATA FROM FILE REPRESENTATION")
                return
        }
        
        guard let tempImage = UIImage.init(data: imageData)
            else {
                print("FAILED TO CONVERT IMAGE DATA TO UIIMAGE")
                return
        }
        
        image = tempImage
        
        NotificationCenter.default.post(name: .didReceiveImage, object: nil)
    }
    
    func getPhoto() -> UIImage {
        return image!
    }
    
    func saveImageToPhotosAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    func startRunningSession() {
        DispatchQueue.global(qos: .userInitiated).async {
        self.capturePhotoSession?.startRunning()
        }
    }
    
    func stopRunningSession() {
        capturePhotoSession?.stopRunning()
    }
}

extension Notification.Name {
    static let didReceiveImage = Notification.Name("didReceiveImage")
}
