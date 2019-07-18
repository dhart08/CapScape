//
//  KMLFileBuilder.swift
//  CaptureScape
//
//  Created by David on 2/12/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import UIKit

struct KMLFileBuilder {
    
    func showKMLExportAlertController(controller: UIViewController, onSave: @escaping (_ placemarkName: String, _ description: String) -> Void) {
        
        let alertController = UIAlertController(title: "Export KML File", message: "Enter a place name and description:", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Place Name"
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Description"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            onSave(alertController.textFields![0].text!, alertController.textFields![1].text!)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        controller.present(alertController, animated: true, completion: nil)
    }
    
    func createKMLFile(placemarkName: String, description: String, latitude: String, longitude: String) -> String {
        
        var contents: String = ""
        
        contents.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n")
        contents.append("<kml xmlns=\"http://earth.google.com/kml/2.2\">\r\n")
            contents.append("<Placemark>\r\n")
                contents.append("<name>\(placemarkName)</name>\r\n")
                contents.append("<description>\(description)</description>\r\n")
                contents.append("<Point>\r\n")
                    contents.append("<coordinates>\r\n")
                        contents.append("\(latitude),\(longitude),0\r\n")
                    contents.append("</coordinates>\r\n")
                contents.append("</Point>\r\n")
            contents.append("</Placemark>\r\n")
        contents.append("</kml>")
        
        return contents
    }
    
    func saveKMLFile(contents: String, filename: String) {
        //print("saveKMLFile()")
        
        let directoryHandler = DirectoryHandler()
        directoryHandler.createDirectory(dirType: .kml)
        directoryHandler.changeDirectory(dirType: .kml, url: nil)
        
        do {
            let fileManager = FileManager.default
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let kmlDirURL = documentsURL.appendingPathComponent("KML")
            
            //clean this up
            let filename = URL(string: filename)?.deletingPathExtension()
            let fileURL = kmlDirURL.appendingPathComponent((filename)!.absoluteString).appendingPathExtension("kml")
           
            try contents.write(to: fileURL, atomically: true, encoding: .utf8)
            
            //print("made file: ", result)
            
        } catch {
            print(error.localizedDescription)
        }
    }
}
