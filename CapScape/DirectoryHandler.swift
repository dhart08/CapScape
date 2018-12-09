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
    
    private var fileMgr: FileManager!
    
    init() {
        fileMgr = FileManager()
    }
    
    func changeDirectory(type: directoryType) -> Bool {
        let dirPaths = fileMgr.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDir = dirPaths[0]
        
        switch type {
            case .appDocuments:
                fileMgr.changeCurrentDirectoryPath(docsDir.path)
                return true
            default:
                fileMgr.changeCurrentDirectoryPath(docsDir.appendingPathComponent(type.rawValue).path)
            return true
        }
    }
    
    func createDirectory(type: directoryType) {
        let dirPaths = fileMgr.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDir = dirPaths[0]
        let newDir = docsDir.appendingPathComponent(type.rawValue).path
        
        do {
            try fileMgr.createDirectory(atPath: newDir, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("\(error.localizedDescription)")
        }
    }
    
    func listDirectoryContents() {
        do {
            let fileList = try fileMgr.contentsOfDirectory(atPath: fileMgr.currentDirectoryPath)
            
            for filename in fileList {
                print("\(filename)")
            }
        }
        catch {
            print("\(error.localizedDescription)")
        }
        
        print("printed folder contents!")
    }
    
}
