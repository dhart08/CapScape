//
//  DirectoryHandler.swift
//  CapScape
//
//  Created by David on 11/25/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import Foundation



final class DirectoryHandler {
    
    enum directoryType: String {
        case appDocuments = "Documents"
        case videos = "Videos"
        case photos = "Photos"
        case slideshows = "Slideshows"
    }
    
    init() {
        
    }
    
    func changeDirectory(dirType: directoryType) {
        let documentsDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(dirType.rawValue)
        
        FileManager.default.changeCurrentDirectoryPath(documentsDir.path)
    }
    
    func createDirectory(dirType: directoryType) {
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDir = dirPaths[0]
        let newDir = docsDir.appendingPathComponent(dirType.rawValue).path
        
        do {
            try FileManager.default.createDirectory(atPath: newDir, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("\(error.localizedDescription)")
        }
    }
    
    func listDirectoryContents() {
        do {
            let fileList = try FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath)
            
            for filename in fileList {
                print("\(filename)")
            }
        }
        catch {
            print("\(error.localizedDescription)")
        }
        
        print("printed folder contents!")
    }
    
    func getDocumentsPath() -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        return documentsDir
    }
    
}
