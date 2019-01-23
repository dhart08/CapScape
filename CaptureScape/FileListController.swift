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
    
    @IBOutlet weak var navigationbar: UINavigationBar!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var selectAllButton: UIBarButtonItem! {
        didSet {
            let myBarButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
            myBarButton.backgroundColor = UIColor.clear
            myBarButton.setTitle("Select All", for: .normal)
            myBarButton.setTitleColor(UIColor.init(red: 0, green: 0.478431, blue: 1.0, alpha: 1.0), for: .normal)
            myBarButton.alpha = 0.0
            //myBarButton.addTarget(self, action: #selector(self.selectAllButtonClick), for: .touchUpOutside)
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.selectAllButtonClick))
            tapGestureRecognizer.cancelsTouchesInView = false
            myBarButton.addGestureRecognizer(tapGestureRecognizer)
            
            selectAllButton.customView = myBarButton
        }
    }
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    let thumbnailCache = NSCache<NSString, UIImage>()
    var directoryHandler: DirectoryHandler!
    var contentsList: [String] = []
    var selectedIndexes: [IndexPath]! = []
    var inSelectMode = false
    var dropboxUploader: DropboxUploader! = nil
    var passUploaderToMainView: ((DropboxUploader) -> Void)?
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        print("FileListController: viewDidAppear")
        
        // fire off batch upload
    }
    
    // MARK: Element Action Functions -------------------------------------------------
    
    @IBAction func backButtonClick(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectButtonClick(_ sender: UIBarButtonItem) {
        if sender.title == "Select" {
            sender.title = "Cancel"
            
            UIView.animate(withDuration: 0.5) {
                self.selectAllButton.customView?.alpha = 1.0
            }
            
            tableView.allowsMultipleSelection = true
            inSelectMode = true
        } else {
            sender.title = "Select"
            
            UIView.animate(withDuration: 0.5) {
                self.selectAllButton.customView?.alpha = 0.0
            }
            
            //print(tableView.indexPathsForSelectedRows)
            
            tableView.allowsMultipleSelection = false
            inSelectMode = false
        }
    }
    
    @objc func selectAllButtonClick() {
        print("selectAllButton clicked!")
        
        for row in 1 ... tableView.numberOfRows(inSection: 0) - 1 {
            print("selecting row: \(row)")
            tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
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
                
                let uploadBatchFiles = {
                    let folder = "/\(self.directoryHandler.currentDirectory.lastPathComponent)"
                    var urlList: [URL]! = []
                    
                    for indexPath in currentSelection! {
                        //print(indexPath)
                        let url = URL(string: "\(self.directoryHandler.currentDirectory!)\(self.contentsList[indexPath.row])")!
                        urlList.append(url)
                    }
                    
                    self.dropboxUploader.uploadBatchFilesToDropBox(controller: self, urls: urlList, folder: folder, completion: nil)
                }
                
                if self.dropboxUploader == nil || self.dropboxUploader.dropboxClient == nil {
                    self.dropboxUploader = DropboxUploader()
                    self.dropboxUploader.startAuthorizationFlow(controller: self) {
                        self.passUploaderToMainView?(self.dropboxUploader)
                        uploadBatchFiles()
                    }
                } else {
                    uploadBatchFiles()
                }
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
        myCell.cellThumbnailImage.alpha = 0.0
        
        let cellText = self.contentsList[indexPath.row]
        myCell.cellFilenameLabel.text = cellText
        
        //doesn't work for bottom rows
        if selectedIndexes.contains(indexPath) {
            print("reselecting cell")
            myCell.isSelected = true
        }
        
        if cellText == "..." {
            myCell.selectionStyle = UITableViewCellSelectionStyle.none
        }
        
        var thumbnailImage: UIImage!
        DispatchQueue.global().async() {
            thumbnailImage = self.getThumbnail(url: self.directoryHandler.currentDirectory.appendingPathComponent(self.contentsList[indexPath.row]))
            
            DispatchQueue.main.sync {
                myCell.cellThumbnailImage.image = thumbnailImage
                
                UIView.animate(withDuration: 0.2, animations: {
                    myCell.cellThumbnailImage.alpha = 1.0
                })
            }
        }
        
        // TODO: Make all selected cells greyed out while scrolling
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedCellURL: URL = directoryHandler.currentDirectory
        selectedCellURL.appendPathComponent(contentsList[indexPath.row])
        
        // if directory is selected
        if directoryHandler.isDirectory(url: selectedCellURL) {
            openDirectory(url: selectedCellURL)
        }
        // if directory up is selected
        else if contentsList[indexPath.row] == "..." {
            if inSelectMode {
                tableView.deselectRow(at: indexPath, animated: false)
            } else {
                directoryHandler.changeDirectory(dirType: .specific, url: directoryHandler.currentDirectory.deletingLastPathComponent())
            
                openDirectory(url: directoryHandler.currentDirectory)
            }
        }
        // if selecting a single cell
        else if !inSelectMode {
            let fileViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FileViewController") as? FileViewController
            fileViewController?.fileURL = selectedCellURL
            fileViewController?.passUploaderToFileList = { uploader in
                print("passed client to FileList and MainView")
                self.dropboxUploader = uploader
                
                self.passUploaderToMainView?(uploader)
            }
            
            if let dropboxUploader = dropboxUploader {
                print("passed existing client to FileViewController")
                fileViewController?.dropboxUploader = dropboxUploader
            }
            
            present(fileViewController!, animated: true, completion: nil)
        }
        // if in multi-select mode
        else {
            print("inSelectMode = true: selected row")
            if !selectedIndexes.contains(indexPath) {
                selectedIndexes.append(indexPath)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cellsSelected = tableView.indexPathsForSelectedRows
        
        if cellsSelected == nil {
            selectButton.title = "Select"
            inSelectMode = false
        }
        
        if selectedIndexes.contains(indexPath) {
            selectedIndexes.remove(at: selectedIndexes.firstIndex(of: indexPath)!)
            //print("deselected row!!!")
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
