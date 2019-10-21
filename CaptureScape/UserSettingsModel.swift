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
    private var imageNumber: String?
    private var askForImageComment: Bool?
    
    private let expirationDateKey = "ExpirationDate"
    private let userHeightKey = "UserHeight"
    private let imagePrefixKey = "ImagePrefix"
    private let askForImageCommentKey = "AskForImageComment"
    
    init() {
        
    }
    
    public func getExpirationDate() -> String? {
        print("getExpirationDate()")
        if expirationDate == nil {
            expirationDate = UserDefaults.standard.string(forKey: expirationDateKey) // <--- never stored one in the first place
        }
        
        print("end of getExpirationDate()")
        return expirationDate
    }
    
    public func setExpirationDate(date: String) {
        print("setExpirationDate()")
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
    
    public func setImagePrefix(prefix: String?) {
        //UserDefaults.standard.set(prefix, forKey: imagePrefixKey)
        
        if (prefix == nil) || (prefix == "") {
            imagePrefix = nil
        }
        else {
            imagePrefix = prefix
        }
    }
    
    public func getImageNumber() -> String? {
        return imageNumber
    }
    
    public func setImageNumber(num: String?) {
        if (num == nil) || (num == "") {
            imageNumber = nil
        }
        else {
            imageNumber = num
        }
    }
    
    public func getAskForImageComment() -> Bool {
        askForImageComment = UserDefaults.standard.bool(forKey: askForImageCommentKey)
        
        return askForImageComment!
    }
    
    public func setAskForImageComment(value: Bool) {
        UserDefaults.standard.set(value, forKey: askForImageCommentKey)
    }
}
