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
    private var filePrefix: String?
    private var fileCount: Int?
    private var askForImageComment: Bool?
    
    private let expirationDateKey = "ExpirationDate"
    private let userHeightKey = "UserHeight"
    private let filePrefixKey = "FilePrefix"
    private let fileCountKey = "FileCount"
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
    
    public func setAppCloseWithPrefix(result: Bool) {
        UserDefaults.standard.set(result, forKey: "AppCloseWithPrefix")
    }
    
    public func getAppCloseWithPrefix() -> Bool? {
        let result: Bool? = UserDefaults.value(forKey: "AppCloseWithPrefix") as? Bool
        
        return result
    }
    
    public func getFilePrefix() -> String? {
        let prefix = UserDefaults.standard.value(forKey: filePrefixKey) as? String
        
        return prefix
    }
    
    public func setFilePrefix(prefix: String?) {
        if (prefix == nil) || (prefix == "") {
            filePrefix = nil
        }
        else {
            filePrefix = prefix
        }
        
        UserDefaults.standard.set(filePrefix, forKey: filePrefixKey)
    }
    
    public func getFileCount() -> Int? {
        let fileCount = UserDefaults.standard.value(forKey: fileCountKey) as? Int
        
        return fileCount
    }
    
    public func setFileCount(num: Int?) {
        if (num == nil) {//|| (num == "") {
            fileCount = nil
        }
        else {
            fileCount = num
        }
        
        UserDefaults.standard.set(fileCount, forKey: fileCountKey)
    }
    
    public func getAskForImageComment() -> Bool {
        askForImageComment = UserDefaults.standard.bool(forKey: askForImageCommentKey)
        
        return askForImageComment!
    }
    
    public func setAskForImageComment(value: Bool) {
        UserDefaults.standard.set(value, forKey: askForImageCommentKey)
    }
}
