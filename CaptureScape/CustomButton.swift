//
//  CustomButton.swift
//  CaptureScape
//
//  Created by David on 12/10/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable

class CustomButton: UIButton {
    //@IBInspectable
//    var borderColor: UIColor? {
//        get {
//            if let color = layer.borderColor {
//                return UIColor(cgColor: color)
//            }
//            return nil
//        }
//
//        set {
//            if let color = newValue {
//                layer.borderColor = color.cgColor
//            } else {
//                layer.borderColor = nil
//            }
//        }
//    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0 ? true : false
        }
    }
}
