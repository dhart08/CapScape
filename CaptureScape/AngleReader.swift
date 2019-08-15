//
//  AngleReader.swift
//  CaptureScape
//
//  Created by David on 8/6/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import Foundation
import CoreMotion

final class AngleReader {
    private var motionManager: CMMotionManager?
    private var timer: Timer?
    
    private let motionInterval: Double = 0.1
    private var pitch: Double! = 0
    private var roll: Double! = 0
    private var yaw: Double! = 0
    
    var pitch1: Double?
    var pitch2: Double?
    
    init() {
        motionManager = CMMotionManager()
    }
    
    func startTrackingDeviceMotion() {
        if (motionManager?.isDeviceMotionAvailable)! {
            motionManager?.deviceMotionUpdateInterval = motionInterval
            motionManager?.startDeviceMotionUpdates(to: OperationQueue(), withHandler: { (motion, error) in
                if let attitude: CMAttitude = motion?.attitude {
                    
                    self.pitch = round(attitude.pitch * 180 / Double.pi)
                    self.roll = round(attitude.roll * 180 / Double.pi)
                    self.yaw = round(attitude.yaw * 180 / Double.pi)
                    
                    print("pitch: ", self.pitch!, "\troll: ", self.roll!, "\tyaw: ", self.yaw!)
                }
            })
        }
    }
    
    func stopTrackingDeviceMotion() {
        self.motionManager?.stopDeviceMotionUpdates()
    }
    
    private func startGyroscopes() {
        if (motionManager?.isGyroAvailable)! {
            motionManager?.gyroUpdateInterval = 0.5
            motionManager?.startGyroUpdates()
            
            timer = Timer(fire: Date(), interval: 1.0, repeats: true, block: { (timer) in
                
                if let gyroData = self.motionManager?.gyroData {
                    let x = gyroData.rotationRate.x
                    let y = gyroData.rotationRate.y
                    let z = gyroData.rotationRate.z
                    
                    print("x: ", x, "\ty: ", y, "\tz: ", z)
                }
            })
            
            RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)
        }
    }
    
    private func stopGyroscopes() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
            
            motionManager?.stopGyroUpdates()
        }
    }
    
    func getCurrentPitch() -> Double {
        return pitch
    }
    
    func getAngleFromPitches() -> Double? {
        if (pitch1 == nil) || (pitch2 == nil) {
            return nil
        }
        
        let angle: Double = pitch1! - pitch2!
        
        return angle
    }
    
    func clearPitches() {
        pitch1 = nil
        pitch2 = nil
    }
}
