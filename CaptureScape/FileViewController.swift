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
    var dropboxUploader: DropboxUploader!
    var fileURL: URL!
    var passUploaderToFileList: ((DropboxUploader) -> Void)?
    
    // MARK: ViewController Functions --------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        if dropboxUploader != nil {
            
            //TODO: Check if file already exists on Dropbox
            
            let uploadFolder = "/\(fileURL.deletingLastPathComponent().lastPathComponent)"
            
            dropboxUploader.createDropboxFolder(name: uploadFolder)
            dropboxUploader.uploadFileToDropbox(controller: self, url: fileURL, folder: uploadFolder) {
                self.populateFileAttributes()
                self.setUploadButtonLook()
            }
        } else {
            // TODO: need to make sure user has internet connection here
            
            let uploader = DropboxUploader()
            
//            uploader.executeUponLogin = {
//                self.dropboxUploader = uploader
//                self.passUploaderToFileList?(self.dropboxUploader)
//
//                self.populateFileAttributes()
//                self.setUploadButtonLook()
//            }
            
            uploader.startAuthorizationFlow(controller: self) {
                self.dropboxUploader = uploader
                self.passUploaderToFileList?(self.dropboxUploader)
                
                self.populateFileAttributes()
                self.setUploadButtonLook()
            }
        }
    }
    
    // MARK: Helper Functions ----------------------------------------------------------
    
    func populateFileAttributes() {
        let fileDictionary = try! FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = String(describing: fileDictionary[FileAttributeKey.size]!)
        let fileCreationDate = String(describing: fileDictionary[FileAttributeKey.creationDate]!)
        
        
        filenameLabel.text = fileURL.lastPathComponent
        fileSizeLabel.text = fileSize
        fileCreationLabel.text = fileCreationDate
        
        if hasInternetConnection && dropboxUploader != nil {
            dropboxUploader.isFileOnline(url: fileURL) { (exists) in
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
        if dropboxUploader != nil {
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
    
}
