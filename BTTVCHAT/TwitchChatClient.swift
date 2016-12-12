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
    var num = 1
    
    var images = [String : UIImage]()
    var bttvEmoteId = [String: String]()
    var bttvEmoteUrlTemplate: String?
    
    let client:TCPClient = TCPClient(addr: "irc.chat.twitch.tv", port: 6667)
    var pass: String? = "oauth:3jzkmsisl13cls2529jezdrl20xqdk"
    var nick: String? = "kawolum822"
    var channel: String?
    var headerAcceptKey = "Accept"
    var headerAcceptValue = "application/vnd.twitchtv.v5+json"
    var headerClientIDKey = "Client-ID"
    var headerClientIDValue = "3jrodo343bfqtrfs2y0nnxfnn0557j0"
    
    let concurrentLineQueue = DispatchQueue(label: "com.kawolum.bttvChat.lineQueue", attributes: .concurrent)
    
    let concurrentMessageQueue = DispatchQueue(label: "com.kawolum.bttvChat.messageQueue", attributes: .concurrent)
    
    init(channel: String){
        self.channel = channel
    }
    
    func start(){
        DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
            let (success,errmsg) = self.client.connect(timeout: 10)
            
            if success{
                DispatchQueue.global(qos: DispatchQoS.utility.qosClass).async {self.beginReadingData()}
                self.authenticate()
                self.joinChannel()
                if self.isJoinComplete() {
                    DispatchQueue.global(qos: DispatchQoS.userInitiated.qosClass).async {self.beginReadingLines()}
                }else{
                    print("failed to configure chat")
                }
            }else{
                print(errmsg)
            }
            
            print("done")
        }
    }
    
    func authenticate(){
        if pass != nil && nick != nil {
            var (success,errmsg) = client.send(str: "PASS " + pass! + "\r\n")
            (success,errmsg) = client.send(str: "NICK " + nick! + "\r\n")
        }else{
            print("pass or nick is nil")
        }
    }
    
    func joinChannel(){
        if channel != nil{
            var (success,errmsg) = client.send(str: "CAP REQ :twitch.tv/tags\r\n")
            (success,errmsg) = client.send(str: "JOIN #" + channel! + "\r\n")
        }else{
            print("channel is nil")
        }
    }
    
    func isJoinComplete() -> Bool{
        while(true){
            if !lines.isEmpty {
                var line : String?
                concurrentLineQueue.sync{
                    line = lines.removeFirst()
                }
                if let newLine = line{
                    if newLine.hasSuffix("End of /NAMES list"){
                        return true
                    }
                }
            }
        }
    }
    
    func beginReadingData(){
        print("Begin Reading Data")
        
        while(true){
            if let linesFromData = self.getLinesFromData(){
                for line in linesFromData {
                    concurrentLineQueue.async{
                        self.lines.append(line)
                        //print(line)
                    }
                }
            }
        }
    }
    
    func beginReadingLines(){
        print("Begin Reading lines")
        
        while(true){
            if !lines.isEmpty {
                var line : String?
                concurrentLineQueue.sync{
                    line = lines.removeFirst()
                }
                if line!.hasPrefix("PING"){
                    pongBack(pingLine: line!)
                }else {
                    if let message = parseMessage(line: line!){
                        concurrentMessageQueue.async{
                            self.messages.append(message)
                        }
                    }
                }
            }
        }
    }
    
    func pongBack(pingLine: String){
        let newLine = pingLine.replacingOccurrences(of: "PING", with: "PONG")
        let (success,errmsg) = self.client.send(str: newLine)
        print((success ? newLine : errmsg))
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
    
    func parseMessage(line:String) -> Message?{
        do {
            let input = line
            let regex = try NSRegularExpression(pattern: "^@badges=(.*);color=(.*);display-name=(.*);emotes=(.*);id=(?:.*);mod=([01]{1});room-id=([0-9]*);(?:sent-ts=.*;)?subscriber=([01]{1});(?:tmi-sent-ts=[0-9]*)?;turbo=([01]{1});user-id=([0-9]*);user-type=(.*) PRIVMSG #\(channel!) :(.*)$")
            let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
            
            if let match = matches.first {
                let lastRangeIndex = match.numberOfRanges - 1
                var attributes = [String]()
                
                for i in 1...lastRangeIndex{
                    let range = match.rangeAt(i)
                    if let swiftRange = range.range(for: input) {
                        let string = line.substring(with: swiftRange)
                        attributes.append(string)
                    }
                }
                let message = Message(attributes: attributes)
                return message
            }else{
                print("line did not match regular expression")
                print(line)
            }
        } catch {
            print("regular expression error")
        }
        
        return nil
    }
    
    func addMessage(message: Message){
        messages.append(message)
    }
    
    func peek() -> Message?{
        return messages.first
    }
    
    func pop() -> Message?{
        if messages.count < 1{
            return nil
        }
        
        let message = messages.removeFirst()
        return message
    }
}
