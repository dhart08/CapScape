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
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var fileCreationLabel: UILabel!
    @IBOutlet weak var myButton: UIButton!
    
    var dropboxClient: DropboxClient!
    var fileURL: URL!
    private var cancelUpload: Bool = false
    var passClientToFileList: ((DropboxClient) -> Void)?
    
    // MARK: ViewController Functions --------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(createDropboxClient), name: .userWasLoggedIn, object: nil)
        
        placeMediaInPlayerView()
        populateFileAttributes()
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
    
    @IBAction func loginButtonClick(_ sender: UIButton) {
        if dropboxClient == nil {
            startAuthorizationFlow()
            return
        }
        
        print("User already logged in!")
    }
    
    @IBAction func myButtonClick(_ sender: UIButton) {
        createDropboxFolder(name: "/Photos")
        uploadFileToDropbox(url: fileURL, folder: "/Photos")
    }
    
    // MARK: Helper Functions ----------------------------------------------------------
    
    func startAuthorizationFlow() {
        print("startAuthorizationFlow")
        
        DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self, openURL: { (url) in
                print("opening URL...")
                UIApplication.shared.open(url)
            }
        )
    }
    
    @objc func createDropboxClient() {
        print("createDropboxClient")
        dropboxClient = DropboxClientsManager.authorizedClient
        passClientToFileList?(dropboxClient)
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
    
    func uploadFileToDropbox(url: URL, folder: String) {
        print("uploadFileToDropbox")
        
        let dropboxPath = "\(folder)/\(url.lastPathComponent)"
        
        let request = dropboxClient.files.upload(path: dropboxPath, input: url).response { response, error in
            if let response = response {
                print("\(response)")
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
    }
    
    private func placeMediaInPlayerView() {
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

extension Notification.Name {
    static let userWasLoggedIn = Notification.Name("userWasLoggedin")
}
