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
    var heading: Double! = 0
    
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
            locationManager.startUpdatingHeading()
        }
        
        print("LocationFinder:startFindingLocation")
    }
    
    func stopFindingLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        
        print("LocationFinder:stopFindingLocation")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location: CLLocation = locations[0]
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        
        NotificationCenter.default.post(name: .didReceiveCoordinates, object: nil, userInfo: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        var tempHeading: Double = newHeading.trueHeading
        
        if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
                tempHeading += 90.0
            }
            else {
                tempHeading -= 90.0
            }
        }
        
        heading = tempHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error:\(error)")
    }
    
    func decimalToDMSString(latitude: Double, longitude: Double) -> (String, String) {
        let latSuffix = latitude > 0.0 ? "N" : "S"
        let latDegrees = abs(Int(latitude / 1))
        var latRemainder = Double(latitude.truncatingRemainder(dividingBy: 1.0))
        let latMin = abs(Int(latRemainder * 60))
        latRemainder = latRemainder * 60
        latRemainder = Double(latRemainder.truncatingRemainder(dividingBy: 1.0))
        var latSec = abs(latRemainder * 60)
        latSec = round(latSec*100)/100
        
        let lonSuffix = longitude < 0.0 ? "W" : "E"
        let lonDegrees = abs(Int(longitude / 1))
        var lonRemainder = Double(longitude.truncatingRemainder(dividingBy: 1.0))
        let lonMin = abs(Int(lonRemainder * 60))
        lonRemainder = lonRemainder * 60
        lonRemainder = Double(lonRemainder.truncatingRemainder(dividingBy: 1.0))
        var lonSec = abs(lonRemainder * 60)
        lonSec = round(lonSec*100)/100
        
        //return (deg, min, sec)
        return ("\(latDegrees)° \(latMin)' \(latSec)\" \(latSuffix)", "\(lonDegrees)° \(lonMin)' \(lonSec)\" \(lonSuffix)")
    }
    
    func getCardinalDirection() -> String {
        var direction = ""
        
        switch (heading) {
        case let heading where heading! > 337.5:
            direction = "N"
        case let heading where heading! > 292.5:
            direction = "NW"
        case let heading where heading! > 247.5:
            direction = "W"
        case let heading where heading! > 202.5:
            direction = "SW"
        case let heading where heading! > 157.5:
            direction = "S"
        case let heading where heading! > 112.5:
            direction = "SE"
        case let heading where heading! > 67.5:
            direction = "E"
        case let heading where heading! > 22.5:
            direction = "NE"
        default:
            direction = "N"
        }
        
        return direction
    }
}

extension Notification.Name {
    static let didReceiveCoordinates = Notification.Name("didReceiveCoordinates")
}
