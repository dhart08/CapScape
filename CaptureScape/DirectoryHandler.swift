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
        case appDocuments
        case photos = "Photos"
        case videos = "Videos"
        case slideshows = "Slideshows"
        case kml = "KML"
        case specific
    }
    
    private var fileManager: FileManager!
    var currentDirectory: URL!
    
    init() {
        fileManager = FileManager()
        changeDirectory(dirType: .appDocuments, url: nil)
    }
    
    func changeDirectory(dirType: directoryType, url: URL?) {
        var documentsDir: URL!
        
        if dirType == .specific {
            documentsDir = url
        }
        else if dirType == .appDocuments {
            do {
                documentsDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            } catch {
                print(error.localizedDescription)
            }
        }
        else {
            do {
                documentsDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(dirType.rawValue)
                print("made ", dirType.rawValue)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        fileManager.changeCurrentDirectoryPath(documentsDir.path)
        currentDirectory = documentsDir
    }
    
    func createDirectory(dirType: directoryType) {
        let dirPaths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDir = dirPaths[0]
        let newDir = docsDir.appendingPathComponent(dirType.rawValue).path
        
        do {
            try fileManager.createDirectory(atPath: newDir, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("\(error.localizedDescription)")
        }
    }
    
    func getDirectoryContents() -> [String]{
        var dirContents: [String]!
        
        do {
            dirContents = try fileManager.contentsOfDirectory(atPath: fileManager.currentDirectoryPath)
        }
        catch {
            print("\(error.localizedDescription)")
        }
        
        return dirContents
    }
    
    func getDocumentsPath() -> URL {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        return documentsDir
    }
    
    func isDirectory(url: URL) -> Bool {
        var isDirectory: ObjCBool = ObjCBool(false)
        
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            return isDirectory.boolValue
        }
        else {
            //print("ERROR isDirectory(): FILE DOESN'T EXIST!!!")
        }
        
        return false
    }
}
