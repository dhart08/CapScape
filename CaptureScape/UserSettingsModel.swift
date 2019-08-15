//
//  UserSettingsModel.swift
//  CaptureScape
//
//  Created by David on 8/12/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import Foundation

class UserSettingsModel {
    private var expirationDate: String?
    private var userHeight: Int?
    private var imagePrefix: String?
    
    private let expirationDateKey = "ExpirationDate"
    private let userHeightKey = "UserHeight"
    private let imagePrefixKey = "ImagePrefix"
    
    init() {
        
    }
    
    public func getExpirationDate() -> String? {
        if expirationDate == nil {
            expirationDate = UserDefaults.value(forKey: expirationDateKey) as? String
        }
        
        return expirationDate
    }
    
    public func setExpirationDate(date: String) {
        UserDefaults.standard.set(date, forKey: expirationDateKey)
    }
    
    public func getUserHeight() -> Int? {
        //userHeight = UserDefaults.value(forKey: userHeightKey) as? Int
        
        return userHeight
    }
    
    public func setUserHeight(height: Int) {
        //UserDefaults.standard.set(height, forKey: userHeightKey)
        userHeight = height
    }
    
    public func getImagePrefix() -> String? {
        //imagePrefix = UserDefaults.value(forKey: imagePrefixKey) as? String
        
        return imagePrefix
    }
    
    public func setImagePrefix(prefix: String) {
        //UserDefaults.standard.set(prefix, forKey: imagePrefixKey)
        imagePrefix = prefix
    }
}
