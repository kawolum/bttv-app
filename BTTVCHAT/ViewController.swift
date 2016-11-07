//
//  ViewController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/3/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate{
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var chatTextView: UITextView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let client:TCPClient = TCPClient(addr: "irc.chat.twitch.tv", port: 6667)
    var pass: String? = "oauth:3jzkmsisl13cls2529jezdrl20xqdk"
    var nick: String? = "kawolum822"
    var channel: String? = "lol_peanut"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextField()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureChat()
    }
    
    func configureChat(){
        DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
            let (success,errmsg) = self.client.connect(timeout: 10)
            
            if success{
                self.authenticate()
                self.joinChannel()
                if self.isJoinComplete() {
                    self.beginReadingChat()
                }else{
                    print("failed to configure chat")
                }
            }else{
                print(errmsg)
            }
        }
    }
    
    func configureTextField(){
        messageTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    func readLine()->String?{
        var line:String?
        
        let data = client.read(1024)
        
        if let d = data{
            if let str = String(bytes: d, encoding: String.Encoding.utf8){
                line = str
            }
        }
        
        return line
    }
    
    func authenticate(){
        if pass != nil && nick != nil {
            var (success,errmsg) = client.send(str: "PASS " + pass! + "\r\n")
            print((success ? "PASS " + pass! : errmsg))
            (success,errmsg) = client.send(str: "NICK " + nick! + "\r\n")
            print((success ? "NICK " + nick! : errmsg))
        }else{
            print("pass or nick is nil")
        }
    }
    
    func joinChannel(){
        if channel != nil{
            var (success,errmsg) = client.send(str: "JOIN #" + channel! + "\r\n")
            print((success ? "JOIN #" + channel! : errmsg))
            (success,errmsg) = client.send(str: "CAP REQ :twitch.tv/tags\r\n")
            print((success ? "send CAP REQ :twitch.tv/tags\r\n" : errmsg))
        }else{
            print("channel is nil")
        }
    }
    
    func isJoinComplete() -> Bool{
        while(true){
            if let line = readLine(){
                if line.contains("End of /NAMES list"){
                    return true
                }
            }else{
                return false
            }
        }
    }
    
    func beginReadingChat(){
        var reading = true
        
        while(reading){
            if let line = self.readLine(){
                if line.hasPrefix("PING") {
                    let newLine = line.replacingOccurrences(of: "PING", with: "PONG")
                    let (success,errmsg) = self.client.send(str: newLine)
                    print((success ? newLine : errmsg))
                }else{
                    parseMessage(line: line)
                }
            }else{
                reading = false
            }
        }
    }
    
    func parseMessage(line:String){
        do {
            let input = line
            let regex = try NSRegularExpression(pattern: "^@badges=(.*);color=(.*);display-name=(.*);emotes=(.*);id=(?:.*);mod=([01]{1});room-id=([0-9]*);(?:sent-ts=.*;)?subscriber=([01]{1});(?:tmi-sent-ts=[0-9]*)?;turbo=([01]{1});user-id=([0-9]*);user-type=(.*) PRIVMSG #" + channel! + " :(.*)$")
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
                appendMessagetoView(message: message)
            }
        } catch {
            print("regular expression error")
        }
    }
    
    func appendMessagetoView(message:Message){
        DispatchQueue.main.async{
            self.chatTextView.text.append(message.displayName + ": " + message.message + "\r\n")
            let range = NSMakeRange((self.chatTextView.text?.characters.count)! - 1, 0)
            self.chatTextView.scrollRangeToVisible(range)
        }
    }
    
    @IBAction func sendButtonPressed(_ sender: UIButton) {
        if let message = messageTextField.text{
            if(message != ""){
                messageTextField.text = ""
                messageTextField.endEditing(true)
                sendButton.isHidden = true
                DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
                    let newMessage = "PRIVMSG #" + self.channel! + " :" + message + "\r\n"
                    let (success,errmsg) = self.client.send(str: newMessage)
                    print((success ? newMessage : errmsg))
                }
            }
        }
    }

    @IBAction func textFieldDidChange(_ sender: UITextField) {
        if let text = sender.text{
            if(text == ""){
                sendButton.isHidden = true
            }else{
                sendButton.isHidden = false
            }
        }
    }

    func keyboardWillShow(notification: NSNotification) {
        
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        self.bottomConstraint.constant += keyboardFrame.height
    }
    
    func keyboardWillHide(notification: NSNotification) {
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        self.bottomConstraint.constant = 0
    }
}

extension NSRange {
    func range(for str: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }
        
        guard let fromUTFIndex = str.utf16.index(str.utf16.startIndex, offsetBy: location, limitedBy: str.utf16.endIndex) else { return nil }
        guard let toUTFIndex = str.utf16.index(fromUTFIndex, offsetBy: length, limitedBy: str.utf16.endIndex) else { return nil }
        guard let fromIndex = String.Index(fromUTFIndex, within: str) else { return nil }
        guard let toIndex = String.Index(toUTFIndex, within: str) else { return nil }
        
        return fromIndex ..< toIndex
    }
}
