//
//  DropBoxUploader.swift
//  CaptureScape
//
//  Created by David on 1/7/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import Foundation
import SwiftyDropbox

final class DropboxUploader {
    var dropboxClient: DropboxClient!
    private var fileUploadRequest: UploadRequest<Files.FileMetadataSerializer, Files.UploadErrorSerializer>!
    private var batchUploadRequest: BatchUploadTask!
    private var cancelledBatchUpload: Bool! = false
    private var executeUponLogin: (() -> Void)?
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(createDropboxClient), name: .userWasLoggedIn, object: nil)
    }
    
    func startAuthorizationFlow(controller: UIViewController, uponLogin: (() -> Void)? = nil) {
        print("startAuthorizationFlow")
        
        executeUponLogin = uponLogin
        
        DropboxClientsManager.authorizeFromController(
            UIApplication.shared,
            controller: controller,
            openURL: { (url) in
                UIApplication.shared.open(url)
            }
        )
    }
    
    @objc func createDropboxClient() {
        print("createDropboxClient")
        dropboxClient = DropboxClientsManager.authorizedClient
        
        if executeUponLogin != nil {
            executeUponLogin?()
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
    
    func uploadFileToDropbox(controller: UIViewController, url: URL, folder: String, completion: @escaping () -> Void) {
        print("uploadFileToDropbox")
        
        let dropboxPath = "\(folder)/\(url.lastPathComponent)"
        
        //let topController = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
        
        let tpv = TransferProgressView(controller: controller, title: "1 File(s)", message: "Uploading: \(url.lastPathComponent)")
        tpv.onCancelClick = { self.cancelFileUpload() }
        tpv.show()
        
        fileUploadRequest = dropboxClient.files.upload(path: dropboxPath, input: url).response { response, error in
            if let response = response {
                //runs after uploading complete
                print(response)
                tpv.close()
                DispatchQueue.main.async {
                    completion()
                }
            } else if let error = error {
                print("ERROR: \(error)")
            }
        }
        
        fileUploadRequest.progress { progressData in
            print(progressData.fractionCompleted)
            tpv.setProgress(progress: progressData.fractionCompleted)
        }
    }
    
    func uploadBatchFilesToDropBox(controller: UIViewController, urls: [URL], folder: String, completion: (() -> Void)?) {
        
        let tpv = TransferProgressView(controller: controller, title: "Uploading \(urls.count) File(s)", message: "Uploading:")
        tpv.onCancelClick = { self.cancelFileUpload() }
        tpv.show()

        let fileCount = urls.count
        let uploadGroup = DispatchGroup()
        
        // TODO: Works, but needs to be refined and looked at for errors.
        
        DispatchQueue.global().async {
            
            var fileNum = 0
            
            for url in urls {
                uploadGroup.enter()
                
                if self.cancelledBatchUpload {
                    uploadGroup.leave()
                    continue
                }

                let dropboxPath = "\(folder)/\(url.lastPathComponent)"
                DispatchQueue.main.async {
                    fileNum = fileNum + 1
                    tpv.setTitle(title: "Uploading file \(fileNum) of \(fileCount) File(s)")
                    tpv.setMessage(message: "Uploading: \(url.lastPathComponent)")
                }
                
                self.fileUploadRequest = self.dropboxClient.files.upload(path: dropboxPath, input: url).response { response, error in
                    if let _ = response {
                        //runs after uploading complete
                        //fileCount = fileCount - 1
                        uploadGroup.leave()
                    } else if let error = error {
                        print("ERROR: \(error)")
                    }
                }
                
                self.fileUploadRequest.progress { progressData in
                    tpv.setProgress(progress: progressData.fractionCompleted)
                }
                
                uploadGroup.wait()
                
                if fileNum == fileCount {
                    DispatchQueue.main.async {
                        tpv.close()
                    }
                    
                    self.cancelledBatchUpload = false
                }
                //end of single url
            }
            //end of for url in urls
        }
    }
    
    func cancelFileUpload() {
        fileUploadRequest.cancel()
    }
    
    func cancelBatchUpload() {
        fileUploadRequest.cancel()
        cancelledBatchUpload = true
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
    
    func getOnlineFolderContents(folder: String) -> [String] {
        return []
    }
}

extension Notification.Name {
    static let userWasLoggedIn = Notification.Name("userWasLoggedIn")
}
