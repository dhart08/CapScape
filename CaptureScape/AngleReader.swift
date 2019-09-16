//
//  AngleReader.swift
//  CaptureScape
//
//  Created by David on 8/6/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import Foundation
import CoreMotion

struct Angle {
    var pitch: Double! = 0
    var roll: Double! = 0
    var yaw: Double! = 0
    var gravityX: Double! = 0
    var gravityY: Double! = 0
    var gravityZ: Double! = 0
    var heading: Double! = 0
    var altitude: Double! = 0
    
    func getAngle() -> Double {
        let angle = 90.0 - pitch
        
        return angle
    }
    
    func getHeight(distance: Double) -> Double {
        let angle = self.getAngle()
        let height = tan(angle * Double.pi / 180) * distance
        
        return height
    }
}

final class AngleReader {
    private var motionManager: CMMotionManager?
    private var timer: Timer?
    
    private var altimeter: CMAltimeter?
    
    private let motionInterval: Double = 0.25
    
    private var pitch: Double! = 0
    private var roll: Double! = 0
    private var yaw: Double! = 0
    private var gravityX: Double! = 0
    private var gravityY: Double! = 0
    private var gravityZ: Double! = 0
    private var altitude: Double! = 0
    
    var angle1: Angle?
    var angle2: Angle?
    
    init() {
        motionManager = CMMotionManager()
    }
    
    func startTrackingDeviceMotion() {
        
        if (motionManager?.isDeviceMotionAvailable)! {
            motionManager?.deviceMotionUpdateInterval = motionInterval
            motionManager?.startDeviceMotionUpdates(to: OperationQueue(), withHandler: { (motion, error) in
                
                if let gravity: CMAcceleration = motion?.gravity {
                    self.gravityX = round(gravity.x * 1000)
                    self.gravityY = round(gravity.y * 1000)
                    self.gravityZ = round(gravity.z * 1000)
                    //print("gravityX: ", self.gravityX!, "\t\tgravityY: ", self.gravityY!, "\t\tgravityZ: ", self.gravityZ!)
                }
                
                if let attitude: CMAttitude = motion?.attitude {
                    
                    self.pitch = round(attitude.pitch * 180 / Double.pi)
                    self.roll = round(attitude.roll * 180 / Double.pi)
                    self.yaw = round(attitude.yaw * 180 / Double.pi)
                    
                    //print("pitch: ", self.pitch!, "\troll: ", self.roll!, "\tyaw: ", self.yaw!)
                }
            })
        }
    }
    func stopTrackingDeviceMotion() {
        self.motionManager?.stopDeviceMotionUpdates()
    }
    
    func startTrackingDeviceRelativeAltitude() {
        altimeter = CMAltimeter()
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            
            altimeter?.startRelativeAltitudeUpdates(to: .main, withHandler: { (data, error) in
                if data != nil {
                    self.altitude = Double(exactly: data!.relativeAltitude)
                    self.altitude = self.altitude * 100
                    self.altitude = round(self.altitude)
                    self.altitude = self.altitude / 100
                    
                    print("relativeAltitude: \(self.altitude!)")
                }
            })
        }
    }
    
    func stopTrackingDeviceRelativeAltitude() {
        altimeter?.stopRelativeAltitudeUpdates()
    }
    
    
    
//    private func startGyroscopes() {
//        if (motionManager?.isGyroAvailable)! {
//            motionManager?.gyroUpdateInterval = 0.5
//            motionManager?.startGyroUpdates()
//
//            timer = Timer(fire: Date(), interval: motionInterval, repeats: true, block: { (timer) in
//
//                if let gyroData = self.motionManager?.gyroData {
//                    let x = gyroData.rotationRate.x
//                    let y = gyroData.rotationRate.y
//                    let z = gyroData.rotationRate.z
//
//                    //print("x: ", x, "\ty: ", y, "\tz: ", z)
//                }
//            })
//
//            RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)
//        }
//    }
//
//    private func stopGyroscopes() {
//        if timer != nil {
//            timer?.invalidate()
//            timer = nil
//
//            motionManager?.stopGyroUpdates()
//        }
//    }
    
//    func getHeightFromPitches(angle1: Angle, angle2: Angle) -> Double? {
//        if (angle1.pitch == nil) || (angle2.pitch == nil) {
//            return nil
//        }
//
//        let result: Double = angle1.pitch - angle2.pitch
//
//        return result
//    }
    
//    func clearPitches() {
//        pitch1 = nil
//        pitch2 = nil
//    }
    
    
    func getCurrentPitch() -> Double {
        return pitch
    }
    
    func getCurrentRoll() -> Double {
        return roll
    }
    
    func getCurrentYaw() -> Double {
        return yaw
    }
    
    func getCurrentGravityX() -> Double {
        return gravityX
    }
    
    func getCurrentGravityY() -> Double {
        return gravityY
    }
    
    func getCurrentGravityZ() -> Double {
        return gravityZ
    }
    
    func getCurrentRelativeAltitude() -> Double {
        return altitude
    }
    
    func getCurrentAngle(heading: Double = 0, altitude: Double = 0) -> Angle {
        var angle: Angle = Angle()
        angle.pitch = pitch
        angle.roll = roll
        angle.yaw = yaw
        angle.gravityX = gravityX
        angle.gravityY = gravityY
        angle.gravityZ = gravityZ
        angle.heading = heading
        angle.altitude = altitude
        
        return angle
    }
    
    func clearAngles() {
        angle1 = nil
        angle2 = nil
    }
    
    func getHeightFromAngles(angle1: Angle, angle2: Angle, distance: Double) -> Double {
        let feetInMeter = 3.28084
        
        let height1 = angle1.getHeight(distance: distance) * angle1.gravityZ / abs(angle1.gravityZ)
        let height2 = angle2.getHeight(distance: distance) * angle2.gravityZ / abs(angle2.gravityZ)
        let altitudeDifference = feetInMeter * abs(angle1.altitude - angle2.altitude)
        
//        if (angle1.gravityZ < 0) && (angle2.gravityZ < 0) {
//            // subtract a2.height from a1.height
//            totalHeight = height1 - height2
//        }
//        else if (angle1.gravityZ < 0) && (angle2.gravityZ > 0) {
//            //add both heights together
//            totalHeight = height1 + height2
//        }
//        else {
//            //subtract angle1.height from angle2.height
//            totalHeight = height2 - height1
//        }
        
        var totalHeight = 0.0
        totalHeight = abs(height1 - height2) + altitudeDifference
        
        return totalHeight
    }
    
    func getWidthFromAngles(angle1: Angle, angle2: Angle, distance: Double) -> Double {
        print("Heading1: ", angle1.heading, "\t\tHeading2: ", angle2.heading)
        
        var angle = abs(angle1.heading - angle2.heading)
        if angle > 180.0 {
            angle = 360.0 - angle
        }
        
        let midAngle = angle / 2.0
        let width = (tan(midAngle * Double.pi / 180.0) * distance) * 2.0
        
        return width
    }
}
