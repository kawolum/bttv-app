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
    var channel: String?
    var emoteController: EmoteController?
    var badgeController: BadgeController?
    
    init(channel: String){
        super.init()
        self.channel = channel
        do{
            self.lineRegex = try NSRegularExpression(pattern: "^@(badges)=(.*);(?:(bits)=(.*);)?(color)=(.*);(display-name)=(.*);(emotes)=(.*);id=.*;mod=[01]{1};room-id=[a-zA-Z0-9]*;(?:sent-ts=.*;)?subscriber=[01]{1};(?:tmi-sent-ts=.*)?;turbo=[01]{1};user-id=.*;user-type=.* (:)(.*)!.*@.*(PRIVMSG) #.* :(.*)$")
        }catch{
            print("regular expression error")
        }
        emoteController = EmoteController(channel: channel)
        badgeController = BadgeController(channel: channel)
    }
    
    func createMessage(line : String) -> Message?{
        if let attributes = parseMessage(line: line), let message = createMessageWithAttributes(attributes: attributes) {
            emoteController?.createEmotes(message: message)
            createNSAttributedString(message: message)
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
//                case "bits":
//                    message.bits = value
//                    break;
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
                    message.emoteString = value
                    break;
                case ":":
                    message.username = value
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
    
    func createNSAttributedString(message: Message){
        let finalString = NSMutableAttributedString()
        
        for badge in message.badges {
            if let badgeImage = badgeController!.getBadgeImage(badgeName: badge){
                let badgeAttachment = NSTextAttachment()
                badgeAttachment.image = badgeImage
                
                let badgeString = NSAttributedString(attachment: badgeAttachment)
                
                finalString.append(badgeString)
                finalString.append(NSAttributedString(string: " "))
            }
        }
        
        var displayNameAttributes = [String: Any]()        
        
        if message.color.isEmpty {
            if let color = DisplayNameColorCache.getColor(key: message.username){
                displayNameAttributes[NSForegroundColorAttributeName] = color
            }else{
                let color = randomColor()
                displayNameAttributes[NSForegroundColorAttributeName] = color
                DisplayNameColorCache.setColor(key: message.username, value: color)
            }
        }else{
            displayNameAttributes[NSForegroundColorAttributeName] = hexStringToUIColor(hex:message.color)
        }
        let displayNameString = NSAttributedString(string: message.displayname.isEmpty ? message.username : message.displayname, attributes: displayNameAttributes)
        finalString.append(displayNameString)
        finalString.append(NSAttributedString(string: ": "))
        
        var currentIndex = 0;
        var currentString = ""
        var skip = 0
        var currentEmotesIndex = 0
        
        for index in message.message.characters.indices{
            if skip > 0{
                skip -= 1
            }else{
                if message.emotes.count > currentEmotesIndex, currentIndex == message.emotes[currentEmotesIndex].startIndex{
                    if !currentString.isEmpty{
                        finalString.append(NSAttributedString(string: currentString))
                        currentString = ""
                    }
                    
                    if let emoteImage = emoteController!.getEmoteImage(emote: message.emotes[currentEmotesIndex]){
                        let emoteAttachment = NSTextAttachment()
                        emoteAttachment.image = emoteImage
                        
                        let emoteString = NSAttributedString(attachment: emoteAttachment)
                        
                        finalString.append(emoteString)
                    }
                    skip = message.emotes[currentEmotesIndex].length - 1
                    currentEmotesIndex += 1
                }else{
                    currentString.append(message.message[index])
                }
            }
        
            currentIndex += 1
        }
        
        if !currentString.isEmpty {
            finalString.append(NSAttributedString(string: currentString))
        }

        message.nsAttributedString = finalString
    }
    
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.characters.count) != 6) {
            return randomColor()
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func randomColor() -> UIColor {
        
        let randomRed:CGFloat = CGFloat(drand48())
        
        let randomGreen:CGFloat = CGFloat(drand48())
        
        let randomBlue:CGFloat = CGFloat(drand48())
        
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
}
