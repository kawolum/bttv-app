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
    var messages = [Message]()
    
    let client:TCPClient = TCPClient(addr: "irc.chat.twitch.tv", port: 6667)
    var pass: String? = "oauth:3jzkmsisl13cls2529jezdrl20xqdk"
    var nick: String? = "kawolum822"
    
//    let headerAcceptKey = "Accept"
//    let headerAcceptValue = "application/vnd.twitchtv.v5+json"
//    let headerClientIDKey = "Client-ID"
//    let headerClientIDValue = "3jrodo343bfqtrfs2y0nnxfnn0557j0"
    
    var channel: String?
    var messageController : MessageController?
    
    init(channel: String){
        super.init()
        self.channel = channel
        
    }
    
    func start(){
        let (success,errmsg) = self.client.connect(timeout: 10)
            
        if success{
            messageController = MessageController(channel: channel!)
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
                    self.messages.append(message)
                    notifyNewMessage()
                }
            }else{
                print("not parse: \(line)")
            }
        }
    }
    
    func notifyNewMessage(){
        NotificationCenter.default.post(name: NSNotification.Name("newMessage"), object: nil)
    }
    
    func pongBack(line: String){
        let newLine = line.replacingOccurrences(of: "PING", with: "PONG")
        let (success,errmsg) = self.client.send(str: newLine)
        print((success ? newLine : errmsg))
    }
    
    func sendMessage(string: String){
        //need to parse sent message
        let line = "PRIVMSG #" + self.channel! + " :" + string + "\r\n"
        let (success,errmsg) = self.client.send(str: line)
        print((success ? "worked" : errmsg))
    }
}
