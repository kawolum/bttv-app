//
//  Message.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/6/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

import UIKit

class Message: NSObject {
    var badges:[String]?
    var color = ""
    var displayName = ""
    var emotes:[String]?
    var mod = false
    var subscriber = false
    var roomid = ""
    var turbo = false
    var userid = ""
    var userType = ""
    var message = ""
    
    init(attributes:[String]) {
        
        badges = attributes[0].components(separatedBy: ",")
        color = attributes[1]
        displayName = attributes[2]
        emotes = attributes[3].components(separatedBy: "/")
        if attributes[4] == "1"{
            subscriber = true
        }
        roomid = attributes[5]
        if attributes[6] == "1"{
            turbo = true
        }
        if attributes[7] == "1"{
            mod = true
        }
        userid = attributes[8]
        userType = attributes[9]
        message = attributes[10]
        
        if displayName == "" {
            if let startIndex = userType.indexOfCharacter(char: ":"), let endIndex = userType.indexOfCharacter(char: "!"){
                let start = userType.index(userType.startIndex, offsetBy: 1 + startIndex)
                let end = userType.index(userType.startIndex, offsetBy: endIndex)
                let range = start..<end
                displayName = userType.substring(with: range)
            }
        }
        
    }
}
extension String {
    public func indexOfCharacter(char: Character) -> Int? {
        if let idx = characters.index(of: char) {
            return characters.distance(from: startIndex, to: idx)
        }
        return nil
    }
}
