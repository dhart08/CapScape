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
    
    func takePhoto() {
        capturePhotoSession?.startRunning()
        print("CAPTUREPHOTOSESSION STARTED RUNNING")
        
        photoSettings = AVCapturePhotoSettings()
        photoSettings!.isHighResolutionPhotoEnabled = true
        photoOutput!.capturePhoto(with: photoSettings!, delegate: self)
        
        capturePhotoSession?.stopRunning()
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
}

extension Notification.Name {
    static let didReceiveImage = Notification.Name("didReceiveImage")
}
