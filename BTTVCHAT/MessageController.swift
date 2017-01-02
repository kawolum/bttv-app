//
//  MessageController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 12/18/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

import UIKit

class MessageController: NSObject {
    
    var lineRegex : NSRegularExpression? = nil
    var bttvEmotesDictionary : [String : String]?
    
    init(bttvEmotesDictionary: [String : String]){
        super.init()
        self.bttvEmotesDictionary = bttvEmotesDictionary
        
        do{
            self.lineRegex = try NSRegularExpression(pattern: "^@(badges)=(.*);(?:(bits)=(.*);)?(color)=(.*);(display-name)=(.*);(emotes)=(.*);(id)=(.*);(mod)=([01]{1});(room-id)=([a-zA-Z0-9]*);(?:(sent-ts)=(.*);)?(subscriber)=([01]{1});(?:(tmi-sent-ts)=(.*))?;(turbo)=([01]{1});(user-id)=(.*);(user-type)=(.*) :.*(PRIVMSG) #.* :(.*)$")
        }catch{
            print("regular expression error")
        }
    }
    
    func createMessage(line : String) -> Message?{
        if let attributes = parseMessage(line: line), let message = createMessageWithAttributes(attributes: attributes) {
            checkBTTVEmotes(message : message)
            sortEmotes(message: message)
            for emote in message.emotes{
                print(emote.emoteID)
                print(emote.emoteText)
            }
            return message
        }
        return nil
    }
    
    func parseMessage(line : String) -> [String : String]?{
        if let regex = lineRegex{
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))
            
            if let match = matches.first {
                var attributes = [String : String]()
                
                for i in stride(from: 1, to: match.numberOfRanges, by: 2){
                    var range = match.rangeAt(i)
                    var key : String?
                    var value : String?
                    if let swiftRange = range.range(for: line) {
                        key = line.substring(with: swiftRange)
                    }
                    range = match.rangeAt(i + 1)
                    if let swiftRange = range.range(for: line) {
                        value = line.substring(with: swiftRange)
                    }
                    if key != nil, value != nil{
                        attributes[key!] = value!
                    }
                }
                return attributes
            }else{
                print("PRIVMSG did not match regular expression:")
                print(line)
            }
        }else{
            print("lineRegex is nil")
        }
        
        return nil
    }
    
    func createMessageWithAttributes(attributes : [String : String]) -> Message?{
        let message = Message()
        for (key, value) in attributes {
            if(!value.isEmpty){
                switch(key){
                case "badges":
                    message.badges = value.components(separatedBy: ",").filter{!$0.isEmpty}
                    break;
                case "bits":
                    //IDK
                    break;
                case "color":
                    message.color = value
                    break;
                case "display-name":
                    var displayname = value
                    displayname = value.replacingOccurrences(of: "\\:", with: ";")
                    displayname = value.replacingOccurrences(of: "\\s", with: " ")
                    displayname = value.replacingOccurrences(of: "\\\\", with: "\\")
                    displayname = value.replacingOccurrences(of: "\\r", with: "CR")
                    displayname = value.replacingOccurrences(of: "\\n", with: "LF")
                    message.displayname = displayname
                    break;
                case "emotes":
                    message.emotes = createEmotes(emoteString: value)
                    break;
                case "id":
                    message.id = value
                    break;
                case "mod":
                    if value == "1" {
                        message.mod = true
                    }
                    break;
                case "room-id":
                    message.roomid = value
                    break;
                case "sent-ts":
                    message.sentts = value
                    break;
                case "subscriber":
                    if value == "1" {
                        message.subscriber = true
                    }
                    break;
                case "tmi-sent-ts":
                    message.tmisentts = value
                    break;
                case "turbo":
                    if value == "1" {
                        message.turbo = true
                    }
                    break;
                case "user-id":
                    message.userid = value
                    break;
                case "user-type":
                    message.usertype = value
                    break;
                case "PRIVMSG":
                    message.message = value
                    break;
                default:
                    break;
                }
            }
        }
        return message
    }
    
    func createEmotes(emoteString: String) -> [Emote]{
        let differentEmotes = emoteString.components(separatedBy: "/")
        var emotes = [Emote]()
        
        for emote in differentEmotes {
            let emoteIDPositions = emote.components(separatedBy: ":")
            let emoteID = emoteIDPositions[0]
            let emotePositions = emoteIDPositions[1].components(separatedBy: ",")
            
            for i in stride(from: 0, to: emotePositions.count, by: 1){
                let emoteIndexes = emotePositions[i].components(separatedBy: "-")
                if emoteIndexes.count > 1, let startIndex = Int(emoteIndexes[0]), let endIndex = Int(emoteIndexes[1]){
                    emotes.append(Emote(emoteID: emoteID, emoteText: "", startIndex: startIndex, length: endIndex - startIndex + 1, better: false))
                }
            }
        }
        
        return emotes
    }
    
    func checkBTTVEmotes(message: Message){
        if(bttvEmotesDictionary != nil){
            let words = message.message.components(separatedBy: " ")
            var startIndex = 0
            
            for word in words{
                if let id = bttvEmotesDictionary![word]{
                    message.emotes.append(Emote(emoteID: id, emoteText: word, startIndex: startIndex, length: word.characters.count, better: true))
                }
                startIndex += word.characters.count + 1
            }
        }
    }
    
    func sortEmotes(message: Message){
        message.emotes.sort(by: {$0.startIndex < $1.startIndex})
    }
    
    //        if displayName == "" {
    //            if let startIndex = userType.indexOfCharacter(char: ":"), let endIndex = userType.indexOfCharacter(char: "!"){
    //                let start = userType.index(userType.startIndex, offsetBy: 1 + startIndex)
    //                let end = userType.index(userType.startIndex, offsetBy: endIndex)
    //                let range = start..<end
    //                displayName = userType.substring(with: range)
    //            }
    //        }
}
