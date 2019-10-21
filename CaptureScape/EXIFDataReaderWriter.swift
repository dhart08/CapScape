//
//  EXITDataReaderWriter.swift
//  CaptureScape
//
//  Created by David on 2/23/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import UIKit

struct EXIFDataParams {
    var latitude: Double?
    var longitude: Double?
    var heading: String?
    var creationDateTime: String?
    var comment: String?
    var makerNote: String?
    
    init(latitude: Double? = nil, longitude: Double? = nil, heading: String? = nil, creationDateTime: String? = nil, comment: String? = nil, makerNote: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.heading = heading
        self.creationDateTime = creationDateTime
        self.comment = comment
        self.makerNote = makerNote
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
    
    func writeEXIFDataToPhoto(fileURL: URL, image: Data, exifDataParams: EXIFDataParams) {
        
        var source: CGImageSource? = nil
        source = CGImageSourceCreateWithData((image as CFData?)!, nil)
        let metadata = CGImageSourceCopyPropertiesAtIndex(source!, 0, nil) as? [AnyHashable: Any]
        var metadataAsMutable = metadata
        var EXIFDictionary = (metadataAsMutable?[(kCGImagePropertyExifDictionary as String)]) as? [AnyHashable: Any]
        var GPSDictionary = (metadataAsMutable?[(kCGImagePropertyGPSDictionary as String)]) as? [AnyHashable: Any]
        //var TIFFDictionary = (metadataAsMutable?[(kCGImagePropertyTIFFDictionary as String)]) as? [AnyHashable: Any]
        
        if EXIFDictionary == nil {
            //print("EXIFDictionary was nil!")
            
            EXIFDictionary = [AnyHashable: Any]()
        }
        if GPSDictionary == nil {
            //print("GPSDictionary was nil!")
            
            GPSDictionary = [AnyHashable: Any]()
        }
        
//        if TIFFDictionary == nil {
//            TIFFDictionary = [AnyHashable: Any]()
//        }
        
        GPSDictionary![kCGImagePropertyGPSLatitude] = exifDataParams.latitude
        GPSDictionary![kCGImagePropertyGPSLongitude] = exifDataParams.longitude
        GPSDictionary![kCGImagePropertyGPSImgDirection] = exifDataParams.heading
        
        EXIFDictionary![kCGImagePropertyExifDateTimeOriginal] = exifDataParams.creationDateTime
        EXIFDictionary![kCGImagePropertyExifUserComment] = exifDataParams.comment
        EXIFDictionary![kCGImagePropertyExifMakerNote] = exifDataParams.makerNote
        //TIFFDictionary![kCGImagePropertyTIFFOrientation] = "2"
        
        
        metadataAsMutable![kCGImagePropertyExifDictionary] = EXIFDictionary
        metadataAsMutable![kCGImagePropertyGPSDictionary] = GPSDictionary
        //metadataAsMutable![kCGImagePropertyTIFFDictionary] = TIFFDictionary
        
        print("******** metadataAsMutable info *********")/////////////
        print(metadataAsMutable!)//////////////////
        
        let UTI: CFString = CGImageSourceGetType(source!)!
        //let destinationData = NSMutableData()
        //let destination: CGImageDestination = CGImageDestinationCreateWithData(destinationData as CFMutableData, UTI, 1, nil)!
        let destination: CGImageDestination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTI, 1, nil)!
        CGImageDestinationAddImageFromSource(destination, source!, 0, (metadataAsMutable as CFDictionary?))
        CGImageDestinationFinalize(destination)
    }
    
}
