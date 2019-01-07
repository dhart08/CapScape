//
//  FileViewerController.swift
//  CaptureScape
//
//  Created by David on 12/27/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import Foundation
import UIKit
import SwiftyDropbox
import AVFoundation
import AVKit

class FileViewController: UIViewController {
    
    @IBOutlet weak var backBarButton: UIBarButtonItem!
    @IBOutlet weak var previewView: CameraView!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var fileCreationLabel: UILabel!
    @IBOutlet weak var fileDropboxLabel: UILabel!
    @IBOutlet weak var uploadButton: CustomButton!
    
    var hasInternetConnection: Bool! = true
    var dropboxClient: DropboxClient!
    var fileURL: URL!
    private var cancelUpload: Bool = false
    var passClientToFileList: ((DropboxClient) -> Void)?
    var executeOnLogin: (() -> Void)?
    
    // MARK: ViewController Functions --------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(createDropboxClient), name: .userWasLoggedIn, object: nil)
        
        placeMediaInPlayerView()
        populateFileAttributes()
        setUploadButtonLook()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    // MARK: Element Action Functions --------------------------------------------------
    
    @IBAction func backBarButtonClick(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func uploadButtonClick(_ sender: UIButton) {
        if dropboxClient != nil {
            let uploadFolder = "/\(fileURL.deletingLastPathComponent().lastPathComponent)"
            
            createDropboxFolder(name: uploadFolder)
            uploadFileToDropbox(url: fileURL, folder: uploadFolder) {
                self.populateFileAttributes()
                self.setUploadButtonLook()
            }
        } else {
            // TODO: need to make sure user has internet connection here
            // TODO: check to see if file is already on dropbox before uploading
            executeOnLogin = {
//                let uploadFolder = "/\(self.fileURL.deletingLastPathComponent().lastPathComponent)"
//
//                self.createDropboxFolder(name: uploadFolder)
//                self.uploadFileToDropbox(url: self.fileURL, folder: uploadFolder) {
//                    self.populateFileAttributes()
//                    self.setUploadButtonLook()
//                }
                
                self.populateFileAttributes()
                self.setUploadButtonLook()
            }
            
            startAuthorizationFlow()
        }
    }
    
    // MARK: Helper Functions ----------------------------------------------------------
    
    func startAuthorizationFlow() {
        print("startAuthorizationFlow")
        
        DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self, openURL: { (url) in
                print("opening URL...")
                UIApplication.shared.open(url)
            }
        )
        
        // TODO: setUploadButtonLook() after login
    }
    
    @objc func createDropboxClient() {
        print("createDropboxClient")
        dropboxClient = DropboxClientsManager.authorizedClient
        passClientToFileList?(dropboxClient)
        
        if executeOnLogin != nil {
            executeOnLogin?()
        }
        
        
    }
    
    func createDropboxFolder(name: String) {
        print("createDropboxFolder")
        
        dropboxClient.files.createFolderV2(path: name).response { response, error in
            if let response = response {
                print(response)
            } else if let error = error {
                print(error)
            }
        }
    }
    
    func uploadFileToDropbox(url: URL, folder: String, completion: @escaping () -> Void) {
        print("uploadFileToDropbox")
        
        let dropboxPath = "\(folder)/\(url.lastPathComponent)"
        
        let request = dropboxClient.files.upload(path: dropboxPath, input: url).response { response, error in
            if let response = response {
                print("\(response)")
                DispatchQueue.main.async {
                    completion()
                }
            } else if let error = error {
                print("ERROR: \(error)")
            }
        }.progress { progressData in
                print(progressData)
        }
        
        if cancelUpload {
            request.cancel()
        }
    }
    
    func populateFileAttributes() {
        let fileDictionary = try! FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = String(describing: fileDictionary[FileAttributeKey.size]!)
        let fileCreationDate = String(describing: fileDictionary[FileAttributeKey.creationDate]!)
        
        
        filenameLabel.text = fileURL.lastPathComponent
        fileSizeLabel.text = fileSize
        fileCreationLabel.text = fileCreationDate
        
        if hasInternetConnection && dropboxClient != nil {
            isFileOnline(url: fileURL) { (exists) in
                if exists {
                    self.fileDropboxLabel.textColor = UIColor.green
                    self.fileDropboxLabel.text = "Yes"
                } else {
                    self.fileDropboxLabel.textColor = UIColor.red
                    self.fileDropboxLabel.text = "No"
                    self.uploadButton.isEnabled = true
                }
            }
        } else {
            self.fileDropboxLabel.textColor = UIColor.red
            self.fileDropboxLabel.text = "User Login Required"
        }
    }
    
    func setUploadButtonLook() {
        if dropboxClient != nil {
            uploadButton.setTitle("Upload", for: .normal)
        } else {
            uploadButton.setTitle("Login", for: .normal)
        }
    }
    
    func placeMediaInPlayerView() {
        print("placeMediaInPreviewView")
        
        let fileType = fileURL.pathExtension
        
        if fileType == "png" || fileType == "jpg" {
            print("placeMediaInPreviewView: found picture")
            
            let previewImage: UIImage!
            previewImage = UIImage(contentsOfFile: fileURL.path)
            
            let myImageView: UIImageView = UIImageView(image: previewImage)
            myImageView.frame = previewView.bounds
            
            previewView.addSubview(myImageView)
            
        } else if fileType == "mp4" {
            print("placeMediaInPreviewView: found video")
            
            let avPlayer = AVPlayer(url: fileURL)
            let avPlayerViewController = AVPlayerViewController()
            avPlayerViewController.player = avPlayer
            avPlayerViewController.view.frame = previewView.bounds
            self.addChildViewController(avPlayerViewController)
            previewView.addSubview(avPlayerViewController.view)
            avPlayerViewController.didMove(toParentViewController: self)
            
        } else {
            let previewImage = UIImage(named: "file_icon")
            
            let myImageView: UIImageView = UIImageView(image: previewImage)
            myImageView.frame = previewView.bounds
            
        }
        
        return
    }
    
    func getOnlineFolderContents(folder: String) -> [String] {
        return []
    }
    
    func isFileOnline(url: URL, completion: @escaping (Bool) -> Void) {
        let folderName = url.deletingLastPathComponent().lastPathComponent
        let filename = url.lastPathComponent
        
        let _ = dropboxClient.files.listFolder(path: "/\(folderName)").response { (listFolderResult, error) in
            if let listFolderResult = listFolderResult {
                for entry in listFolderResult.entries {
                    print(entry.name)
                    if filename == entry.name {
                        DispatchQueue.main.async {
                            completion(true)
                        }
                        
                        return
                    }
                }
                
                completion(false)
            } else {
                print("couldn't get folder contents")
                print(error?.description as Any)
            }
        }
    }
}

extension Notification.Name {
    static let userWasLoggedIn = Notification.Name("userWasLoggedin")
}
