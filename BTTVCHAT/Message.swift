//
//  Message.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/6/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

import UIKit

class Message{
    var badges:[String]?
    var color = ""
    var displayName = ""
    var emotes = [Emote]()
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
        self.populateEmotes(emoteString: attributes[3])
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
    
    func populateEmotes(emoteString: String){        
        var currentEmoteID = ""
        var currentStartIndex = ""
        var currentEndIndex = ""
        var currentState = 1
        for char in emoteString.characters{
            
            switch(char){
                case ":":
                    currentState = 2
                    break;
                case ",":
                    if let currentStartIndexInt = Int(currentStartIndex), let currentEndIndexInt = Int(currentEndIndex) {
                        emotes.append(Emote(emoteID: currentEmoteID, startIndex: currentStartIndexInt, length: currentEndIndexInt - currentStartIndexInt))
                    }
                    currentStartIndex = ""
                    currentEndIndex = ""
                    currentState = 2
                    break;
                case "-":
                    currentState = 3
                    break;
                case "/":
                    if let currentStartIndexInt = Int(currentStartIndex), let currentEndIndexInt = Int(currentEndIndex) {
                        emotes.append(Emote(emoteID: currentEmoteID, startIndex: currentStartIndexInt, length: currentEndIndexInt - currentStartIndexInt))
                    }
                    currentEmoteID = ""
                    currentStartIndex = ""
                    currentEndIndex = ""
                    currentState = 1
                default:
                    switch (currentState) {
                        case 1:
                            currentEmoteID.append(char)
                            break;
                        case 2:
                            currentStartIndex.append(char)
                            break;
                        case 3:
                            currentEndIndex.append(char)
                            break;
                        default:
                            break;
                    }
                    break;
            }
        }
        if let currentStartIndexInt = Int(currentStartIndex), let currentEndIndexInt = Int(currentEndIndex) {
            emotes.append(Emote(emoteID: currentEmoteID, startIndex: currentStartIndexInt, length: currentEndIndexInt - currentStartIndexInt))
        }
        
        emotes.sort(by: {$0.startIndex < $1.startIndex})
    }
}

