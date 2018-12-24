//
//  ControlButton.swift
//  CapScape
//
//  Created by David on 12/10/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable

class ControlButton: UIButton {
    
    @IBInspectable var borderColor: UIColor = UIColor.red {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
}
