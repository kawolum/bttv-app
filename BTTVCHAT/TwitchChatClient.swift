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
    var maxMessages = 200;
    var currIndex = 0;
    
    let client:TCPClient = TCPClient(addr: "irc.chat.twitch.tv", port: 6667)
    var nick: String? = "kawolum822"
    
    var previousLine = ""
    
    var on = false
    
    var channel: Channel?
    var messageController : MessageController?
    
    func setChannel(channel: Channel){
        self.channel = channel
        messages.reserveCapacity(maxMessages)
    }
    
    func start(){
        print("start")
        let (success,errmsg) = self.client.connect(timeout: 10)
        on = success
        if success{
            messageController = MessageController(channel: channel!)
            DispatchQueue.global(qos: DispatchQoS.utility.qosClass).async {self.beginReadingData()}
            self.authenticate()
            self.joinChannel()
        }else{
            print(errmsg)
        }
    }
    
    func stop(){
        on = false
        self.client.close()
    }
    
    func authenticate(){
        if nick != nil {
            var (success,errmsg) = client.send(str: "PASS oauth:\(TwitchAPIManager.sharedInstance.oAuthToken!)\r\n")
            (success,errmsg) = client.send(str: "NICK \(nick!)\r\n")
            
        }else{
            print("pass or nick is nil")
        }
    }
    
    func joinChannel(){
        if channel != nil{
            var (success,errmsg) = client.send(str: "CAP REQ :twitch.tv/tags\r\n")
            (success,errmsg) = client.send(str: "JOIN #\(channel!.name)\r\n")
        }else{
            print("channel is nil")
        }
    }
    
    func beginReadingData(){
        while(on){
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
            pongBack(line: line)
        }else {
            if(line.contains("PRIVMSG")){
                if let message = messageController!.createMessage(line: line) {
                    addMessage(message: message)
                }
            }else{
                print("\(line)")
            }
        }
    }
    
    func addMessage(message: Message){
        if messages.count < maxMessages{
            self.messages.append(message)
        }else{
            messages[currIndex] = message;
            currIndex = (currIndex + 1) % maxMessages;
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newMessage"), object: nil)
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
    
    deinit {
        print("chatclientdeinit")
    }
}

extension TwitchChatClient: UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
        
        let index = (indexPath.row + currIndex) % maxMessages
        
        cell.messageLabel.attributedText = messages[index].nsAttributedString
        
        return cell
    }
}
