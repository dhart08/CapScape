//
//  LicenseValidator.swift
//  CaptureScape
//
//  Created by David on 8/10/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import Foundation
import UIKit

class LicenseValidator {
    private var expirationDate: String? = "10/12/2019" // <----- used for hard coding expiration date
    private let dateFormat: String = "MM/dd/yyyy"
    private let dateFormatter: DateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateFormat = dateFormat
    }
    
    private func getStoredExpirationDate() -> String? {
        let userSettingsModel = UserSettingsModel()
        let date = userSettingsModel.getExpirationDate()
        
        return date
    }
    
    func isCurrentLicenseValid() -> Bool {
        var result: Bool = false
        
        //let storedDate = getStoredExpirationDate() <----- uncomment to get userSettingsModel date
        let storedDate = expirationDate
        
        if storedDate != nil {
            let now = Date()
            let expiration = dateFormatter.date(from: storedDate!)!
            
            if now <= expiration {
                result = true
            }
        }
            //erase after debug
        else {
            print("Could not find license!!!!!")
        }
        
        return result
    }
    
    func askUserForLicense(controller: UIViewController, message: String, completion: @escaping (String, String) -> Void) {
        let alert = UIAlertController(title: "License", message: message, preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: nil)
        alert.textFields![0].placeholder = "Serial"
        alert.addTextField(configurationHandler: nil)
        alert.textFields![1].placeholder = "Key"
        
        let okButton = UIAlertAction(title: "OK", style: .default) { (_) in
            let serial = alert.textFields![0].text
            let key = alert.textFields![1].text
            
            completion(serial!, key!)
        }
        
        alert.addAction(okButton)
        
        controller.present(alert, animated: true, completion: nil)
    }
    
    func convertUserInputToLicense(serial: String, key: String) -> String? {
        
        if serial == "" { return nil }
        else if key == "" { return nil }
        
        //convert serial/key from ascii/hex to UInt8 arrays
        let serialByteArray = serial.asciiToUInt8()
        let keyByteArray = key.hexToUInt8()
        
        //make sure both arrays are same size
        if serialByteArray.count != keyByteArray?.count {
            print("ERROR converUserInputToLicense(): serial/key arrays not same size")
            return nil
        }
        
        //xor serial/key byte arrays into one array
        var xoredByteArray: [UInt8] = []
        for index in 0..<serial.count {
            let xored = serialByteArray[index] ^ keyByteArray![index]
            xoredByteArray.append(xored)
        }
        
        //convert xored byte array into string
        let xoredString = String(bytes: xoredByteArray, encoding: .utf8)?.trimmingCharacters(in: [" "])
        
        return xoredString
    }
    
    func isNewLicenseValid(newLicense: String) -> Bool {
        var result: Bool = false
        
        let storedLicense = getStoredExpirationDate()
        
        print("old license: ", storedLicense!)
        print("new license: ", newLicense)
        
        if storedLicense != nil {
            let new = dateFormatter.date(from: newLicense)!
            let old = dateFormatter.date(from: storedLicense!)!
            
            if old < new {
                result = true
            }
        }
        
        return result
    }
}
    
extension String {
    func asciiToUInt8() -> [UInt8] {
        
        let formattedString = self.trimmingCharacters(in: [" "])
        
        let byteArray = formattedString.utf8.map { (codeUnit) -> UInt8 in
            return UInt8(codeUnit)
        }
        
        return byteArray
    }
    
    func toHexString() -> String {
        var uint8Array: [UInt8] = []
        
        for (index, value) in self.enumerated() {
            //let
        }
        
        return ""
    }
    
    func hexToUInt8() -> [UInt8]? {
        
        let formattedString = self.lowercased().trimmingCharacters(in: [" "])
        
        //check for even number of hex nibbles
        if self.count % 2 == 1 {
            print("ERROR hexToUInt8(): Uneven number of hex characters.")
            return nil
        }
        
        //check for invalid hex characters
        let regex = try! NSRegularExpression(pattern: "[^A-Fa-f0-9]")
        let range = NSRange(location: 0, length: self.utf16.count)
        if regex.firstMatch(in: self, options: [], range: range) != nil {
            print("ERROR hexToUInt8(): Invalid Hex Character")
            return nil
        }
        
        //convert each hex character to its respective hex value
        let nibbleArray = formattedString.map { (character) -> UInt8 in
            UInt8(strtoul(String(character), nil, 16))
        }
        
        //print("hexNibbleArray: ", nibbleArray)
        
        var byteArray: [UInt8] = []
        for index in stride(from: 0, to: nibbleArray.count, by: 2) {
            
            let value1 = nibbleArray[index] * 16
            let value2 = nibbleArray[index + 1]
            
            byteArray.append(value1 + value2)
        }
        
        //print("hexByteArray: ", byteArray)
        
        return byteArray
    }
    
//    func hasNonAlphanumericCharacters() -> Bool {
//
//        var result = false
//
//        return result
//    }
    
    func encryptDecrypt(with cipher: String) ->  String? {
        let str = [UInt8](self.utf8)
        let ciph = [UInt8](cipher.utf8)
        var cipheredArray: [UInt8] = []
        
        for (index, value) in str.enumerated() {
            cipheredArray.append(value ^ ciph[index])
        }
        
        let cipheredString = String(bytes: cipheredArray, encoding: .utf8)
        
        return cipheredString
    }
}
