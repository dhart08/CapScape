//
//  EXITDataReaderWriter.swift
//  CaptureScape
//
//  Created by David on 2/23/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import UIKit
import MobileCoreServices

struct EXIFDataParams {
    var latitude: Double?
    var longitude: Double?
    var heading: String?
    var creationDateTime: String?
    var userComment: String?
    var makerNote: String?
    var uniqueID: String?
    var customAttributes: String?
    
    init(latitude: Double? = nil, longitude: Double? = nil, heading: String? = nil, creationDateTime: String? = nil, userComment: String? = nil, makerNote: String? = nil, uniqueID: String? = nil, customAttributes: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.heading = heading
        self.creationDateTime = creationDateTime
        self.userComment = userComment
        self.makerNote = makerNote
        self.uniqueID = uniqueID
        self.customAttributes = customAttributes
    }
}

struct EXIFDataReaderWriter {
    /*
    func readEXIFDataFromPhoto(fileURL: URL) -> EXIFDataParams {
        
        //let data = UIImagePNGRepresentation(UIImage(contentsOfFile: fileURL.path)!)
        //let source = CGImageSourceCreateWithData((data as CFData?)!, nil)
        
        //check if file exists
        let fileManager = FileManager.default
        let exists = fileManager.fileExists(atPath: fileURL.lastPathComponent)
        print("exists: ", exists, fileURL.lastPathComponent)
        
        let fileManager = FileManager()
        let documentsDir = fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let 
        
        
        //let url = URL(fileURLWithPath: fileURL.absoluteURL)
        let imageData = try! Data(contentsOf: fileURL)
        let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil)
        //let source: CGImageSource = CGImageSourceCreateWithURL(cfurl, nil)!
        //let source: CGImageSource = CGImageSourceCreateWithURL((url as CFURL?)!, nil)!
        let metaData = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil) as? [AnyHashable: Any]
        let exifDictionary = (metaData?[(kCGImagePropertyExifDictionary as String)]) as? [AnyHashable: Any]
        let gpsDictionary = (metaData?[(kCGImagePropertyGPSDictionary as String)]) as? [AnyHashable: Any]
        
        var exifData = EXIFDataParams()
        exifData.latitude = gpsDictionary![kCGImagePropertyGPSLatitude] as? Double
        exifData.longitude = gpsDictionary![kCGImagePropertyGPSLongitude] as? Double
        exifData.creationDateTime = exifDictionary![kCGImagePropertyExifDateTimeOriginal] as? String
        exifData.comment = exifDictionary![kCGImagePropertyExifUserComment] as? String
        
        return exifData
    }
     */
    
    func writeEXIFDataToFileURL(fileURL: URL, image: Data, exifDataParams: EXIFDataParams) {
        
        var source: CGImageSource? = nil
        source = CGImageSourceCreateWithData((image as CFData?)!, nil)
        let metadata = CGImageSourceCopyPropertiesAtIndex(source!, 0, nil) as? [AnyHashable: Any]
        var metadataAsMutable = metadata
        var EXIFDictionary = (metadataAsMutable?[(kCGImagePropertyExifDictionary as String)]) as? [AnyHashable: Any]
        var GPSDictionary = (metadataAsMutable?[(kCGImagePropertyGPSDictionary as String)]) as? [AnyHashable: Any]
        
        if EXIFDictionary == nil {
            //print("EXIFDictionary was nil!")
            
            EXIFDictionary = [AnyHashable: Any]()
        }
        if GPSDictionary == nil {
            //print("GPSDictionary was nil!")
            
            GPSDictionary = [AnyHashable: Any]()
        }
        
        GPSDictionary![kCGImagePropertyGPSLatitude] = exifDataParams.latitude
        GPSDictionary![kCGImagePropertyGPSLongitude] = exifDataParams.longitude
        GPSDictionary![kCGImagePropertyGPSImgDirection] = exifDataParams.heading
        
        EXIFDictionary![kCGImagePropertyExifDateTimeOriginal] = exifDataParams.creationDateTime
        EXIFDictionary![kCGImagePropertyExifUserComment] = exifDataParams.userComment
        EXIFDictionary![kCGImagePropertyExifMakerNote] = exifDataParams.makerNote
        
        
        metadataAsMutable![kCGImagePropertyExifDictionary] = EXIFDictionary
        metadataAsMutable![kCGImagePropertyGPSDictionary] = GPSDictionary
        
        let UTI: CFString = CGImageSourceGetType(source!)!
        //let destinationData = NSMutableData()
        //let destination: CGImageDestination = CGImageDestinationCreateWithData(destinationData as CFMutableData, UTI, 1, nil)!
        let destination: CGImageDestination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTI, 1, nil)!
        CGImageDestinationAddImageFromSource(destination, source!, 0, (metadataAsMutable as CFDictionary?))
        CGImageDestinationFinalize(destination)
    }
    
    func writeEXIFDataToJPEGImage(image: UIImage, exifDataParams: EXIFDataParams) -> Data? {
        // create mutable dictionary
        let data = NSMutableData()
        let metaData = NSMutableDictionary()
        //metaData[ kCGImageDestinationLossyCompressionQuality ] = CGFloat(Constants.JPEG_QUALITY)
        
        // create GPS Dictionary
        let gpsDictionary = NSMutableDictionary()
        gpsDictionary[(kCGImagePropertyGPSLatitude as String)] = abs(exifDataParams.latitude!)
        gpsDictionary[(kCGImagePropertyGPSLatitudeRef) as String] = (exifDataParams.latitude! >= 0.0) ? "N" : "S"
        gpsDictionary[(kCGImagePropertyGPSLongitude as String)] = abs(exifDataParams.longitude!)
        gpsDictionary[(kCGImagePropertyGPSLongitudeRef) as String] = (exifDataParams.longitude! >= 0.0) ? "E" : "W"
        gpsDictionary[(kCGImagePropertyGPSImgDirection) as String] = Double(exifDataParams.heading!)
        
        // create EXIF dictionary
        let exifDictionary = NSMutableDictionary()
        exifDictionary[(kCGImagePropertyExifDateTimeOriginal) as String] = exifDataParams.creationDateTime
        exifDictionary[(kCGImagePropertyExifUserComment) as String] = exifDataParams.userComment
        exifDictionary[(kCGImagePropertyExifMakerNote) as String] = exifDataParams.makerNote
        exifDictionary[(kCGImagePropertyExifImageUniqueID) as String] = exifDataParams.uniqueID
    
        // add GPS/EXIF dictionaries to metadata dictionary
        metaData[kCGImagePropertyGPSDictionary as String] = gpsDictionary
        metaData[kCGImagePropertyExifDictionary as String] = exifDictionary
        
        // create image destination and write to the mutable data object
        let imageDestinationRef = CGImageDestinationCreateWithData(data as CFMutableData, kUTTypeJPEG, 1, nil)!
        // add image to the image destination
        CGImageDestinationAddImage(imageDestinationRef, image.cgImage!, metaData)
        // write image data and properties to the data
        CGImageDestinationFinalize(imageDestinationRef)
        
        // append custom data
        if let attrs = exifDataParams.customAttributes {
            data.append("<CustomAppendedData>\(attrs)</CustomAppendedData>".data(using: .utf8)!)
        }
        
        return data as Data
    }
    
}
