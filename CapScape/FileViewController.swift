//
//  FileViewController.swift
//  CapScape
//
//  Created by David on 12/16/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class FileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    let thumbnailCache = NSCache<NSString, UIImage>()
    var directoryHandler: DirectoryHandler!
    var contentsList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        directoryHandler = DirectoryHandler()
        directoryHandler.changeDirectory(dirType: .appDocuments, url: nil)
        contentsList = directoryHandler.getDirectoryContents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    @IBAction func backButtonClick(_ sender: UIBarButtonItem) {
//        let mv = self.storyboard?.instantiateViewController(withIdentifier: "mainView")
//        self.show(mv!, sender: self)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier") as! CustomFileViewCell
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let myCell = cell as! CustomFileViewCell
        myCell.alpha = 0
        
        var thumbnailImage: UIImage!
        DispatchQueue.global().async() {
            thumbnailImage = self.getThumbnail(url: self.directoryHandler.currentDirectory.appendingPathComponent(self.contentsList[indexPath.row]))
            
            DispatchQueue.main.async {
                myCell.cellThumbnailImage.image = thumbnailImage
                let text = self.contentsList[indexPath.row]
                myCell.cellFilenameLabel.text = text
                
                UIView.animate(withDuration: 0.2, animations: {
                    myCell.alpha = 1
                })
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedCellURL: URL = directoryHandler.currentDirectory
        selectedCellURL.appendPathComponent(contentsList[indexPath.row])
        
        if directoryHandler.isDirectory(url: selectedCellURL) {
            openDirectory(url: selectedCellURL)
        }
        else if contentsList[indexPath.row] == "..." {
            directoryHandler.changeDirectory(dirType: .specific, url: directoryHandler.currentDirectory.deletingLastPathComponent())
            
            openDirectory(url: directoryHandler.currentDirectory)
        }
    }
    
    func getThumbnail(url: URL) -> UIImage? {
        var originalImage: UIImage? = nil
        let cachedImage: UIImage? = nil
        
        if let cachedImage = thumbnailCache.object(forKey: url.absoluteString as NSString) {
            //print("Found picture in cache!")
            return cachedImage
        }
        
        print("\(url.pathExtension)")
        
        if directoryHandler.isDirectory(url: url){
            print("dir")
            originalImage = UIImage(named: "folder_icon")!
        }
        else if url.pathExtension == "" {
            print("parent")
            originalImage = UIImage(named: "parent_directory_icon")
        }
        else if url.pathExtension == "m4a" {
            print("trying to open movie")
            let asset: AVAsset = AVAsset(url: url)
            let assetImageGenerator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let time = CMTimeMakeWithSeconds(1.0, 500)
                let cgImage = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
                originalImage = UIImage(cgImage: cgImage)
            }
            catch {
                print(error.localizedDescription)
                originalImage = UIImage(named: "file_icon")
            }
        }
        else if url.pathExtension == "png" || url.pathExtension == "jpg" {
            print("photo")
            originalImage = UIImage(contentsOfFile: url.path)!
        }
        else {
            print("file")
            
            originalImage = UIImage(named: "file_icon")!
        }
        
        let newSize = CGSize(width: 38, height: 38)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        originalImage!.draw(in: rect)
        
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard cachedImage != nil else {
            //print("Storing picture in cache!")
            thumbnailCache.setObject(resizedImage!, forKey: url.absoluteString as NSString)
            return resizedImage
        }
        
        return resizedImage
    }
    
    func openDirectory(url: URL) {
        directoryHandler.changeDirectory(dirType: .specific, url: url)
        contentsList = directoryHandler.getDirectoryContents()
        
        if directoryHandler.currentDirectory != directoryHandler.getDocumentsPath() {
            contentsList.insert("...", at: 0)
        }
        
        tableView.reloadData()
    }
    
    
}
