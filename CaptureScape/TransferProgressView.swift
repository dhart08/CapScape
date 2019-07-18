//
//  ProgressView.swift
//  CaptureScape
//
//  Created by David on 1/8/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

//import Foundation
import UIKit

class TransferProgressView {
    
    var progressMin: Int!
    var progressMax: Int!
    private var progressValue: Int!
    
    private var popUpController: UIAlertController!
    private var forController: UIViewController!
    private var progressView: UIProgressView!
    var onUploadCompletion: (() -> Void)?
    var onCancelClick: (() -> Void)?
    
    
    init(controller: UIViewController, title: String, message: String) {
        forController = controller
        
        popUpController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        //progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.default)
    }
    
    func show() {
        forController!.present(popUpController, animated: true) {
            self.progressView = self.createProgressBar()
            self.popUpController.view.addSubview(self.progressView)
    
            self.popUpController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.onCancelClick?()
            }))
        }
    }
    
    func close() {
        popUpController.dismiss(animated: true, completion: nil)
    }
    
    private func createProgressBar() -> UIProgressView {
        let progressBar = UIProgressView(frame: CGRect(
            x: 0,
            y: popUpController.view.frame.height,
            width: popUpController.view.frame.width,
            height: 2))
        
        return progressBar
    }
    
    func setProgress(progress: Double) {
        
        guard let progressView = progressView else { return }
        
        progressView.setProgress(Float(progress), animated: false)
    }
    
    func setMessage(message: String) {
        popUpController.message = message
    }
    
    func setTitle(title: String) {
        popUpController.title = title
    }
}
