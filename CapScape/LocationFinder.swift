//
//  LocationFinder.swift
//  CapScape
//
//  Created by David on 9/8/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import UIKit
import CoreLocation

class LocationFinder: NSObject, CLLocationManagerDelegate{
    var locationManager: CLLocationManager!
    
    var latitude: Double!
    var longitude: Double!
    
    override init() {
        super.init()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        print("LocationFinder:init")
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        
        print("LocationFinder:requestAuthorization")
    }
    
    func startFindingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        
        print("LocationFinder:startFindingLocation")
    }
    
    func stopFindingLocation() {
        locationManager.stopUpdatingLocation()
        
        print("LocationFinder:stopFindingLocation")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location: CLLocation = locations[0]
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        
        NotificationCenter.default.post(name: .didReceiveCoordinates, object: nil, userInfo: nil)
        
//        print("LocationFinder:callback")
//        print(latitude)
//        print(longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error:\(error)")
    }
    
    func decimalToDegrees(coordinate: Double) -> (Int, Int, Double) {
        var deg, min: Int
        var sec, remainder: Double
        
        deg = Int(coordinate / 1)
        
        remainder = Double(coordinate.truncatingRemainder(dividingBy: 1.0))
        min = Int(remainder * 60)
        
        remainder = remainder * 60
        remainder = Double(remainder.truncatingRemainder(dividingBy: 1.0))
        sec = remainder * 60
        sec = round(sec*100)/100
        
        return (deg, min, sec)
    }
}

extension Notification.Name {
    static let didReceiveCoordinates = Notification.Name("didReceiveCoordinates")
}
