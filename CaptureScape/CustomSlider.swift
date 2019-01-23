//
//  CustomSlider.swift
//  CaptureScape
//
//  Created by David on 1/23/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

//import Foundation
import UIKit

@IBDesignable

class CustomSlider: UISlider {
    
    @IBInspectable var vertical: Bool = false {
        didSet {
            //layer.setAffineTransform(CGAffineTransform(rotationAngle: rotate))
            self.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        }
    }
}
