//
//  PhotoViewController.swift
//  CapScape
//
//  Created by David on 10/3/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import UIKit
import Foundation


class PhotoViewController: UIViewController {
    
    @IBOutlet weak var photoView: UIView!
    @IBOutlet weak var photoThumbnail: UIImageView!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var snapPhotoButton: UIButton!
    
    struct Annotation {
        var text: NSString
        var textSize: CGFloat
        var point: CGPoint
    }
    
    private var photoCapture: PhotoCapture!
    private var image: UIImage?
    
    private var locationFinder: LocationFinder!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationFinder = LocationFinder()
        photoCapture = PhotoCapture()
        photoCapture?.setupSession()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveCoordinates), name: .didReceiveCoordinates, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveimage(_:)), name: .didReceiveImage, object: nil)
        
        photoCapture.setPhotoPreviewInView(previewView: photoView)
        photoView.bringSubview(toFront: latitudeLabel)
        photoView.bringSubview(toFront: longitudeLabel)
        photoView.bringSubview(toFront: snapPhotoButton)
        photoView.bringSubview(toFront: photoThumbnail)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("PhotoViewController appeared")
        
        locationFinder?.startFindingLocation()
        photoCapture?.startRunningSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("PhotoViewController disappeared")
        
        locationFinder?.stopFindingLocation()
        photoCapture?.stopRunningSession()
    }
    
    @objc func didReceiveCoordinates(_ notification: Notification) {
        if locationFinder.latitude != nil {
            let (latDeg, latMin, latSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.latitude!)
            latitudeLabel.text = "\(latDeg) \(latMin)' \(latSec)''"
        }
        if locationFinder.longitude != nil {
            let (lonDeg, lonMin, lonSec) = locationFinder.decimalToDegrees(coordinate: locationFinder.longitude!)
            longitudeLabel.text = "\(lonDeg) \(lonMin)' \(lonSec)''"
        }
    }
    
    @IBAction func takePhotoButtonClick(_ sender: UIButton) {
        print("takePhotoButtonClicked")
        photoCapture.takePhoto()
    }
    
    @objc func onDidReceiveimage(_ notification: Notification) {
        print("PhotoViewController received image!")
        image = photoCapture.image
        photoThumbnail.image = image
        
        DispatchQueue.main.async {
            if let oldImage = self.image {
//                let latString = NSString(string: "Lat:  \(self.latitudeLabel.text!)")
//                let latStringPoint = CGPoint(x: 0, y: oldImage.size.height - 200)
//                let lonString = NSString(string: "Lon: \(self.longitudeLabel.text!)")
//                let lonStringPoint = CGPoint(x: 0, y: oldImage.size.height - 100)
                
                let latAnnotation = Annotation(
                    text: NSString(string: "Lat:  \(self.latitudeLabel.text!)"),
                    textSize: 100,
                    point: CGPoint(x: 0, y: oldImage.size.height-200)
                )
                
                let lonAnnotation = Annotation(
                    text: NSString(string: "Lon:  \(self.longitudeLabel.text!)"),
                    textSize: 100,
                    point: CGPoint(x: 0, y: oldImage.size.height-100)
                )
                
//                var newImage = self.putTextInImage(text: latString, textSize: 100, atPoint: latStringPoint, oldImage: oldImage)
//                newImage = self.putTextInImage(text: lonString, textSize: 100, atPoint: lonStringPoint, oldImage: newImage)
                
                let newImage = self.putTextInImage(annotations: latAnnotation, lonAnnotation, oldImage: oldImage)
                
                
                self.photoCapture.saveImageToPhotosAlbum(image: newImage)
                print("photo Saved!")
            }
        }
    }
    
    func putTextInImage(annotations: Annotation..., oldImage: UIImage) -> UIImage {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(oldImage.size, false, scale)
        
        //slow!!!
        oldImage.draw(in: CGRect(origin: CGPoint.zero, size: oldImage.size))
        
        for annotation in annotations {
            let color = UIColor.white
            let font = UIFont(name: "Helvetica", size: annotation.textSize)!
            let textFontAttributes = [
                NSAttributedStringKey.font: font,
                NSAttributedStringKey.foregroundColor: color,
                NSAttributedStringKey.backgroundColor: UIColor.black
            ] as [NSAttributedStringKey: Any]
        
            let rect = CGRect(origin: annotation.point, size: oldImage.size)
            annotation.text.draw(in: rect, withAttributes: textFontAttributes)
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
