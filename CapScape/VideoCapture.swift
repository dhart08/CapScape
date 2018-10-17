//
//  VideoCapture.swift
//  CapScape
//
//  Created by David on 9/27/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

class VideoCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //helps transfer data between input devices (camera, mic, etc.) and a view
    var captureVideoSession: AVCaptureSession?
    //helps render the camera view finder in the view controller
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var videoInput: AVCaptureDeviceInput?
    var audioInput: AVCaptureDevice?
    var videoOutput: AVCaptureVideoDataOutput?
    var captureVideoDevice: AVCaptureDevice?
    var movieFileOutput: AVCaptureMovieFileOutput?
    
    var getImage: Bool = false
    var image: UIImage?
    
    func setupSession() {
        //initialize the captureSession object
        captureVideoSession = AVCaptureSession()
        
        //initialize a decive object and provide the video as a media type parameter object
        captureVideoDevice = AVCaptureDevice.default(for: AVMediaType.video)
        //attaches the input device to the capture device
        
        do {
            videoInput = try? AVCaptureDeviceInput(device: captureVideoDevice!)
            audioInput = AVCaptureDevice.default(for: AVMediaType.audio)
            
            videoOutput = AVCaptureVideoDataOutput()
            let videoQueue = DispatchQueue(label: "videoQueue")
            videoOutput!.setSampleBufferDelegate(self, queue: videoQueue)
            
//            if (captureVideoSession?.canAddOutput(videoOutput!))! {
//                captureVideoSession?.addOutput(videoOutput!)
//                print("ADDED OUTPUT TO VIDEO SESSION")
//            }
            
            movieFileOutput = AVCaptureMovieFileOutput()
            if (captureVideoSession?.canAddOutput(movieFileOutput!))! {
                captureVideoSession?.addOutput(movieFileOutput!)
                print("ADDED OUTPUT TO VIDEO SESSION")
            }
        }
        //add the input device to our session
        do {
            captureVideoSession?.addInput(videoInput!)
            try captureVideoSession?.addInput(AVCaptureDeviceInput(device: audioInput!))
        }
        catch {
            print(error)
        }
        
        
        //create an AVCaptureVideoPreviewLayer from the session
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureVideoSession!)
        //configure the layer to resize while maintaining original aspect ratio
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
    }
    
    func setVideoPreviewInView(previewView: UIView) {
        //set preview layer frame to our video controller view bounds
        //videoPreviewLayer?.bounds = view.layer.bounds
        videoPreviewLayer?.frame.size = previewView.frame.size
        //add the preview layer as a sublayer to our cameraView
        previewView.layer.addSublayer(videoPreviewLayer!)
    }
    
    func setVideoOrientation(orientation: AVCaptureVideoOrientation) {
        videoPreviewLayer?.connection?.videoOrientation = orientation
    }
    
    func startRunningSession() {
        //start the capture session
        captureVideoSession?.startRunning()
    }
    
    func stopRunningSession() {
        //stop the capture sesssion
        captureVideoSession?.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("CAPTURED FRAME OUTPUT!!!")
        
        if (getImage == true) {
            let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            let ciImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
            let context: CIContext = CIContext.init(options: nil)
            let cgImage: CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
            image = UIImage.init(cgImage: cgImage)
            
            NotificationCenter.default.post(name: .didReceiveImage, object: nil)
            
            getImage = false
        }
    }
    
    func startRecording() {
        print("recording...")
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = paths[0].appendingPathComponent("myMovie.mov")
        
        try? FileManager.default.removeItem(at: fileURL)
        
        movieFileOutput?.startRecording(to: fileURL, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
    }
    
    func stopRecording() {
        print("stopped recording...")
        movieFileOutput?.stopRecording()
    }
}

extension VideoCapture: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        print("entered save video")
        
        if error == nil {
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
            print("saved recording!")
        }
    }
    
}
