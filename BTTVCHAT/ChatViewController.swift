//
//  ViewController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/3/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

//to do list
//not parse: @badges=;color=;display-name=velocitycake;emotes=3792:0-4;id=d8fb3927-9949-4144-9ff1-049d0137c34b;mod=0;room-id=24538518;sent-ts=
//PRIVMSG did not match regular expression:
//1483422099049;subscriber=0;tmi-sent-ts=1483425708972;turbo=0;user-id=86354680;user-type= :velocitycake!velocitycake@velocitycake.tmi.twitch.tv PRIVMSG #c9sneaky :ANELE
//
//no displayname
//
//gifs
//
//links?

import UIKit

class ChatViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatTableView: UITableView!
    
    var twitchChatClient : TwitchChatClient?
    
    var atBottom = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chatTableView.delegate = self
        chatTableView.dataSource = self
        configureTextField()
        self.twitchChatClient = TwitchChatClient(channel: "meteos")
        chatTableView.rowHeight = UITableViewAutomaticDimension
        chatTableView.estimatedRowHeight = 44
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
            self.twitchChatClient!.start()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTable), name: NSNotification.Name(rawValue: "newMessage"), object: nil)
    }
    
    func reloadTable(){
        if atBottom{
            DispatchQueue.main.async {
                self.chatTableView.reloadData()
                self.chatTableView.scrollToRow(at: IndexPath(row: self.twitchChatClient!.messages.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
            }
        }else{
            DispatchQueue.main.async {
                self.chatTableView.reloadData()
            }
        }
    }
    
    func configureTextField(){
        messageTextField.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @IBAction func sendButtonPressed(_ sender: UIButton) {
        self.chatTableView.reloadData()
        if let message = messageTextField.text{
            if(message != ""){
                messageTextField.text = ""
                messageTextField.endEditing(true)
                sendButton.isHidden = true
                DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
                    self.twitchChatClient?.sendMessage(string: message)
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return twitchChatClient!.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
        
        let index = indexPath.row
        
        cell.messageLabel.attributedText = twitchChatClient!.messages[index].nsAttributedString
        
        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        atBottom = false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if maximumOffset - currentOffset <= 30.0 {
            atBottom = true
        }else{
            atBottom = false
        }
    }
}
