//
//  TwitchChatClient.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 12/10/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

import UIKit

class TwitchChatClient: NSObject {
    var maxMessages = 200
    var lines = [String]()
    var messages = [Message]()
    
    let client:TCPClient = TCPClient(addr: "irc.chat.twitch.tv", port: 6667)
    var pass: String? = "oauth:3jzkmsisl13cls2529jezdrl20xqdk"
    var nick: String? = "kawolum822"
    let headerAcceptKey = "Accept"
    let headerAcceptValue = "application/vnd.twitchtv.v5+json"
    let headerClientIDKey = "Client-ID"
    let headerClientIDValue = "3jrodo343bfqtrfs2y0nnxfnn0557j0"
    
    let bttvGlobalemotesAPIString = "https://api.betterttv.net/2/emotes"
    var bttvChannelemotesAPIString : String?
    var channel: String?
    
    var messageController : MessageController?
    var bttvURLTemplate : String?
    var bttvEmotesDictionary = [String: String]()
    
    var messageAttributedString = [NSAttributedString]()
    
    init(channel: String){
        super.init()
        self.channel = channel
        bttvChannelemotesAPIString = "https://api.betterttv.net/2/channels/\(channel)"
        self.getGlobalBTTVEmotesId()
        self.getChannelBTTVEmotesId()
        messageController = MessageController(bttvEmotesDictionary: bttvEmotesDictionary)
    }
    
    func start(){
        let (success,errmsg) = self.client.connect(timeout: 10)
            
        if success{
            DispatchQueue.global(qos: DispatchQoS.utility.qosClass).async {self.beginReadingData()}
            self.authenticate()
            self.joinChannel()
        }else{
            print(errmsg)
        }
    }
    
    func authenticate(){
        if pass != nil && nick != nil {
            client.send(str: "PASS " + pass! + "\r\n")
            client.send(str: "NICK " + nick! + "\r\n")
        }else{
            print("pass or nick is nil")
        }
    }
    
    func joinChannel(){
        if channel != nil{
            client.send(str: "CAP REQ :twitch.tv/tags\r\n")
            client.send(str: "JOIN #" + channel! + "\r\n")
        }else{
            print("channel is nil")
        }
    }
    
    func beginReadingData(){
        while(true){
            if let linesFromData = self.getLinesFromData(), linesFromData.count > 0{
                for line in linesFromData {
                    self.parseLine(line: line)
                }
            }
        }
    }
    
    func getLinesFromData()->[String]?{
        let data = client.read(1024)
        
        if let d = data{
            if let string = String(bytes: d, encoding: String.Encoding.utf8){
                return string.components(separatedBy: NSCharacterSet.newlines).filter{!$0.isEmpty}
            }
        }
        return nil
    }

    
    func parseLine(line : String){
        if line.hasPrefix("PING"){
            print("pong back")
            pongBack(line: line)
        }else {
            if(line.contains("PRIVMSG")){
                if let message = messageController!.createMessage(line: line) {
                    createNSAttributedString(message: message)
                }
            }else{
                print("not parse: \(line)")
            }
        }
    }
    
    func pongBack(line: String){
        let newLine = line.replacingOccurrences(of: "PING", with: "PONG")
        let (success,errmsg) = self.client.send(str: newLine)
        print((success ? newLine : errmsg))
    }
    
    func createNSAttributedString(message: Message){
        let finalString = NSMutableAttributedString()
        
        
        messageAttributedString.append(finalString)
    }
    
    //    func makeAttributedString(message:Message) -> NSAttributedString {
    //        let finalString = NSMutableAttributedString()
    //
    //        if let badges = message.badges{
    //            for badge in badges{
    //                if let badgeImage = badgeImages[badge]{
    //                    let badgeAttachment = NSTextAttachment()
    //                    badgeAttachment.image = badgeImage
    //
    //                    let badgeString = NSAttributedString(attachment: badgeAttachment)
    //
    //                    finalString.append(badgeString)
    //                }
    //            }
    //        }
    //
    //        let displayNameAttributes = [NSForegroundColorAttributeName: hexStringToUIColor(hex:message.color)]
    //        let displayNameString = NSMutableAttributedString(string: message.displayName, attributes: displayNameAttributes)
    //        finalString.append(displayNameString)
    //
    //        finalString.append(NSAttributedString(string: ": "))
    //
    //        var currentIndex = 0;
    //        var currentString = ""
    //        var skip = 0;
    //
    //        for index in message.message.characters.indices{
    //            if skip > 0{
    //                skip -= 1
    //            }else{
    //                if message.emotes.count > 0, currentIndex == message.emotes[0].startIndex{
    //                    print(message.emotes[0].emoteID)
    //
    //                    finalString.append(NSAttributedString(string: currentString))
    //                    currentString = ""
    //
    //                    if let emote = emoteImages[message.emotes[0].emoteID]{
    //                        print("in array")
    //
    //                        let emoteAttachment = NSTextAttachment()
    //                        emoteAttachment.image = emote
    //
    //                        let emoteString = NSAttributedString(attachment: emoteAttachment)
    //
    //                        finalString.append(emoteString)
    //                    }else{
    //                        print("missing \(message.emotes[0].emoteID)")
    //                    }
    //                    skip = message.emotes[0].length
    //                    message.emotes.removeFirst()
    //
    //
    //                }else{
    //                    currentString.append(message.message[index])
    //                }
    //            }
    //
    //            currentIndex += 1
    //            
    //        }
    //        
    //        if currentString != "" {
    //            finalString.append(NSAttributedString(string: currentString))
    //        }
    //        return finalString
    //    }
    
    func getGlobalBTTVEmotesId(){
        if let emotesAPIURL = URL(string: bttvGlobalemotesAPIString) {
            
            let sema = DispatchSemaphore(value: 0)
            
            var request = URLRequest(url: emotesAPIURL )
            request.httpMethod = "GET"
            
            let session = URLSession.shared
            
            session.dataTask(with: request){ data, response, err in
                if err == nil{
                    if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
                        do {
                            print("global bttv emotes json")
                            let json = try JSONSerialization.jsonObject(with: data!, options: [])
                            
                            if let dictionary = json as? [String: Any], let urlTemplate = dictionary["urlTemplate"] as? String{
                                
                                var newUrlTemplate = "https:"
                                newUrlTemplate.append(urlTemplate.replacingOccurrences(of: "{{image}}", with: "1x"))
                                self.bttvURLTemplate = newUrlTemplate
                                
                                if let emotes = dictionary["emotes"] as? [[String:Any]]{
                                    for emote in emotes{
                                        if let _ = emote["channel"] as? String {
                                            
                                        }else{
                                            if let id = emote["id"] as? String, let code = emote["code"] as? String {
                                                self.bttvEmotesDictionary[code] = id
                                            }
                                        }
                                        
                                    }
                                    
                                    sema.signal()
                                }
                            }
                        } catch let error as NSError {
                            print("Failed to load: \(error.localizedDescription)")
                        }
                        
                    }
                    print("got global bttv emote id")
                }else{
                    print("getBadges: \(err?.localizedDescription)")
                }
            }.resume()
            
            sema.wait()
        }
    }
    
    func getChannelBTTVEmotesId(){
        if let emotesAPIURL = URL(string: bttvChannelemotesAPIString!){
            
            let sema = DispatchSemaphore(value: 0)
            
            var request = URLRequest(url: emotesAPIURL )
            request.httpMethod = "GET"
            
            let session = URLSession.shared
            
            session.dataTask(with: request){ data, response, err in
                if err == nil{
                    if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: [])
                            
                            if let dictionary = json as? [String: Any]{
                                if let emotes = dictionary["emotes"] as? [[String:Any]]{
                                    for emote in emotes{
                                        if let BTTVChannel = emote["channel"] as? String, BTTVChannel == self.channel! {
                                            if let id = emote["id"] as? String, let code = emote["code"] as? String {
                                                self.bttvEmotesDictionary[code] = id
                                            }
                                        }
                                    }
                                    sema.signal()
                                }
                                
                            }
                        } catch let error as NSError {
                            print("Failed to load: \(error.localizedDescription)")
                        }
                        
                    }
                    print("got bttv emote id")
                }else{
                    print("getBadges: \(err?.localizedDescription)")
                }
            }.resume()
            
            sema.wait()
        }
    }
}
