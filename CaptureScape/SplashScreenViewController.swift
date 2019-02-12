//
//  SplashScreenController.swift
//  CaptureScape
//
//  Created by David on 2/6/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import Foundation
import UIKit

class SplashScreenViewController: UIViewController {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var foregroundImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Splash Screen Loaded")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("Splash Screen will appear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("Splash Screen will disappear")
    }
    
}
