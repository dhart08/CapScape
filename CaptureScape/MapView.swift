//
//  MapView.swift
//  CapScape
//
//  Created by David on 12/10/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import Foundation
import UIKit
import MapKit

@IBDesignable

class MapView: MKMapView {
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
}
