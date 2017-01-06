//
//  TwitchChatClient.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 12/10/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

import UIKit

class TwitchChatClient: NSObject {
    var messages = [Message]()
    var maxMessages = 100;
    
    let client:TCPClient = TCPClient(addr: "irc.chat.twitch.tv", port: 6667)
    var pass: String? = "oauth:txhr0l264659q5jxljs4ba7ujjjy8q"
    var nick: String? = "kawolum822"
    
    var previousLine = ""
    
//    let headerAcceptKey = "Accept"
//    let headerAcceptValue = "application/vnd.twitchtv.v5+json"
//    let headerClientIDKey = "Client-ID"
//    let headerClientIDValue = "3jrodo343bfqtrfs2y0nnxfnn0557j0"
    
    var channel: Channel?
    var messageController : MessageController?
    
    init(channel: Channel){
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
            client.send(str: "PASS \(pass!)\r\n")
            client.send(str: "NICK \(nick!)\r\n")
            
        }else{
            print("pass or nick is nil")
        }
    }
    
    func joinChannel(){
        if channel != nil{
            client.send(str: "CAP REQ :twitch.tv/tags\r\n")
            client.send(str: "JOIN #\(channel!.name)\r\n")
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
        if let data = client.read(1024){
            if var string = String(bytes: data, encoding: String.Encoding.utf8){
                if !previousLine.isEmpty{
                    string = previousLine + string
                    previousLine = ""
                }
                var lines = string.components(separatedBy: NSCharacterSet.newlines).filter{!$0.isEmpty}
                if data[data.count - 1] != 10 && data[data.count - 2] != 13{
                    previousLine = lines[lines.count - 1]
                    lines.removeLast()
                }
                return lines
            }
        }
        return nil
    }
    
    func parseLine(line: String){
        if line.hasPrefix("PING"){
            print("pong back")
            pongBack(line: line)
        }else {
            if(line.contains("PRIVMSG")){
                if let message = messageController!.createMessage(line: line) {
                    addMessage(message: message)
                }
            }else{
                print("not parse: \(line)")
            }
        }
    }
    
    func addMessage(message: Message){
        self.messages.append(message)
        if(messages.count > maxMessages){
            messages.removeFirst()
        }
        
        notifyNewMessage()
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
        let line = "PRIVMSG #" + channel!.name + " :" + string + "\r\n"
        let (success,errmsg) = self.client.send(str: line)
        
        let message = Message()
        message.displayname = nick!
        message.username = nick!
        message.message = string
        messageController!.createNSAttributedString(message: message)
        addMessage(message: message)
    }
}
