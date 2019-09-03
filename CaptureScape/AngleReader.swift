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
    var gravity: Double! = 0
    
    init(pitch: Double, gravity: Double) {
        self.pitch = pitch
        self.gravity = gravity
    }
    
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
    
    private let motionInterval: Double = 0.25
    
    private var pitch: Double! = 0
    private var roll: Double! = 0
    private var yaw: Double! = 0
    private var gravityZ: Double! = 0
    
    //var pitch1: Double?
    //var pitch2: Double?
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
                    self.gravityZ = round(gravity.z * 1000)
                    //print("gravityZ: ", self.gravityZ)
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
    
    func getCurrentPitch() -> Double {
        return pitch
    }
    
    func getCurrentGravityZ() -> Double {
        return gravityZ
    }
    
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
    
    func getCurrentAngle() -> Angle {
        let angle: Angle = Angle(pitch: self.pitch, gravity: self.gravityZ)
        
        return angle
    }
    
    func clearAngles() {
        angle1 = nil
        angle2 = nil
    }
    
    func getHeightFromAngles(a1: Angle, a2: Angle, distance: Double) -> Double {
        let height1 = a1.getHeight(distance: distance)
        let height2 = a2.getHeight(distance: distance)
        var totalHeight = 0.0
        
        if (a1.gravity < 0) && (a2.gravity < 0) {
            // subtract a2.height from a1.height
            totalHeight = height1 - height2
        }
        else if (a1.gravity < 0) && (a2.gravity > 0) {
            //add both heights together
            totalHeight = height1 + height2
        }
        else {
            //subtract a1.height from a2.height
            totalHeight = height2 - height1
        }
        
        return totalHeight
    }
}
