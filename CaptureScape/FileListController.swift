//
//  FileListController.swift
//  CapScape
//
//  Created by David on 12/16/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import SwiftyDropbox

class FileListController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var selectbutton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    let thumbnailCache = NSCache<NSString, UIImage>()
    var directoryHandler: DirectoryHandler!
    var contentsList: [String] = []
    var inSelectMode = false
    var dropboxClient: DropboxClient! = nil
    var passClientToMainView: ((DropboxClient) -> Void)?
    
    // MARK: ViewController Functions -------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("FileListController: viewDidLoad")
        
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(cellLongPress))
        longPressGR.minimumPressDuration = 1.0
        tableView.addGestureRecognizer(longPressGR)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        directoryHandler = DirectoryHandler()
        directoryHandler.changeDirectory(dirType: .appDocuments, url: nil)
        contentsList = directoryHandler.getDirectoryContents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("FileListController: viewWillAppear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("FileListController: viewWillDisappear")
    }
    
    // MARK: Element Action Functions -------------------------------------------------
    
    @IBAction func backButtonClick(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectButtonClick(_ sender: UIBarButtonItem) {
        if sender.title == "Select" {
            sender.title = "Cancel"
            
            
            tableView.allowsMultipleSelection = true
            inSelectMode = true
        } else {
            sender.title = "Select"
            
            tableView.allowsMultipleSelection = false
            inSelectMode = false
        }
    }
    
    @objc func cellLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            let touchPoint = sender.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                if indexPath == [0, 0] {
                    return
                }
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            
            let currentSelection = tableView.indexPathsForSelectedRows
            
            let popupMenu = UIAlertController(title: "\(currentSelection!.count) File(s) Selected", message: nil, preferredStyle: .actionSheet)
            
            popupMenu.addAction(UIAlertAction(title: "Upload", style: .default, handler:{ _ in
                print("Upload button pressed")
            }))
            popupMenu.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in
                print("Delete button pressed")
            }))
            
            if currentSelection?.count == 1 {
                popupMenu.addAction(UIAlertAction(title: "Rename", style: .default, handler: { _ in
                    print("Rename button pressed")
                }))
            }
            
            popupMenu.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
                popupMenu.dismiss(animated: true, completion: nil)
            }))
            
            present(popupMenu, animated: true, completion: nil)
        }
    }
    
    // MARK: TableView Functions ------------------------------------------------------
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier") as! CustomFileListCell
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let myCell = cell as! CustomFileListCell
        myCell.alpha = 0
        
        var thumbnailImage: UIImage!
        DispatchQueue.global().async() {
            thumbnailImage = self.getThumbnail(url: self.directoryHandler.currentDirectory.appendingPathComponent(self.contentsList[indexPath.row]))
            
            DispatchQueue.main.async {
                myCell.cellThumbnailImage.image = thumbnailImage
                let cellText = self.contentsList[indexPath.row]
                myCell.cellFilenameLabel.text = cellText
                
                if cellText == "..." {
                    //myCell.cellSwitch.isHidden = true
                    //tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.selectionStyle = UITableViewCellSelectionStyle.none
                    myCell.selectionStyle = UITableViewCellSelectionStyle.none
                }
                
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
            if inSelectMode {
                tableView.deselectRow(at: indexPath, animated: false)
            } else {
                directoryHandler.changeDirectory(dirType: .specific, url: directoryHandler.currentDirectory.deletingLastPathComponent())
            
                openDirectory(url: directoryHandler.currentDirectory)
            }
        }
        else {
            let fileViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FileViewController") as? FileViewController
            fileViewController?.fileURL = selectedCellURL
            fileViewController?.passClientToFileList = { client in
                print("passed client to FileList and MainView")
                self.dropboxClient = client
                
                self.passClientToMainView?(client)
            }
            
            if let dropboxClient = dropboxClient {
                print("passed existing client to FileViewController")
                fileViewController?.dropboxClient = dropboxClient
            }
            
            present(fileViewController!, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let isSelected = tableView.indexPathsForSelectedRows
        
        if isSelected == nil {
            selectbutton.title = "Select"
            inSelectMode = false
        }
    }
    
    // MARK: Helper Functions ---------------------------------------------------------
    
    func getThumbnail(url: URL) -> UIImage? {
        var originalImage: UIImage? = nil
        let cachedImage: UIImage? = nil
        
        if let cachedImage = thumbnailCache.object(forKey: url.absoluteString as NSString) {
            //print("Found picture in cache!")
            return cachedImage
        }
        
        if directoryHandler.isDirectory(url: url){
            //print("dir")
            originalImage = UIImage(named: "folder_icon")!
        }
        else if url.pathExtension == "" {
            //print("parent")
            originalImage = UIImage(named: "parent_directory_icon")
        }
        else if url.pathExtension == "mp4" {
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
            originalImage = UIImage(contentsOfFile: url.path)!
        }
        else {
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
