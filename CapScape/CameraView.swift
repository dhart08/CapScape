//
//  CameraView.swift
//  CapScape
//
//  Created by David on 12/10/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable

class CameraView: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0 ? true : false
        }
    }
}
