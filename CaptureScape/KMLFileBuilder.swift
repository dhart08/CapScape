//
//  KMLFileBuilder.swift
//  CaptureScape
//
//  Created by David on 2/12/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import Foundation

struct KMLFileBuilder {
    
    func createKMLFile(placemarkName: String, description: String, latitude: String, longitude: String) -> String {
        
        var contents: String = ""
        
        contents.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        contents.append("<kml xmlns=\"http://earth.google.com/kml/2.2\">")
            contents.append("<Placemark>")
                contents.append("<name>\(placemarkName)</name>")
                contents.append("<description>\(description)</description>")
                contents.append("<Point>")
                    // add coordinates here
                contents.append("</Point>")
            contents.append("</Placemark>")
        contents.append("</kml>")
        
        return contents
    }
    
    private func saveKMLFile(contents: String, fileURL: URL) {
        // save KML file here
    }
}
