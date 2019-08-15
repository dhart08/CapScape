//
//  LicenseValidator.swift
//  CaptureScape
//
//  Created by David on 8/10/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import Foundation

class LicenseValidator {
    
    private let expirationDate: String = "09-12-2019" //needs to be one day ahead of expiration day
    private let dateFormat: String = "MM-dd-yyyy"
    private let dateFormatter: DateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateFormat = dateFormat
    }
    
    //not used
//    private func getTodaysDateString() -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = dateFormat
//        let date = dateFormatter.string(from: Date())
//
//        return date
//    }
    
    //not used
//    private func getExpirationDate() -> Date {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = dateFormat
//
//        let date = dateFormatter.date(from: expirationDate)
//
//        return date!
//    }
    
    private func getStoredExpirationDate() -> String? {
        let userSettingsModel = UserSettingsModel()
        let date = userSettingsModel.getExpirationDate()
        
        return date
    }
    
    func isLicenseValid() -> Bool {
        var result: Bool = false
        
        // CHANGE THIS TO GET STORED DATE ON PHONE !!!!!!!!!!!!!!!!!!!!!!!!
        //let storedDate = getStoredExpirationDate()
        let storedDate: String? = expirationDate
        
        if storedDate != nil {
            let now = Date()
            let expiration = dateFormatter.date(from: storedDate!)!
            
            if now < expiration {
                result = true
            }
        }
            //erase after debug
        else {
            print("Could not find license!!!!!")
        }
        
        return result
    }
    
//    func validateNewCode(code: String) -> Bool {
//        let keyString = "46758131"
//        let codeString = "45258320"
//
//        let keyBytes = [UInt8](keyString.utf8)
//        let codeBytes = [UInt8](codeString.utf8)
//
//        print("keyBytes: ", keyBytes)
//        print("codeBytes: ", codeBytes)
//
//        var outputBytes = [UInt8]()
//        var byteIndex = 0
//        for _ in keyBytes {
//            let keyByte = keyBytes[byteIndex]
//            outputBytes.append(keyBytes[byteIndex] ^ codeBytes[byteIndex])
//            byteIndex += 1
//        }
//
//        print("outputBytes: ", outputBytes)
//
//        return true
//    }
    
}
