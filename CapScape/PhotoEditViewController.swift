//
//  PhotoEditViewController.swift
//  CapScape
//
//  Created by David on 9/29/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import UIKit

class PhotoEditViewController: UIViewController {
    
    @IBOutlet weak var photoView: UIImageView!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        print("PhotoEditViewController loaded!")
        
        photoView.image = image
    }
}
