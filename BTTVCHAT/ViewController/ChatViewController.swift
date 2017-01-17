//
//  ViewController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/3/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

//to do list
//parse sent message wip
//gifs
//links?

import UIKit
import Foundation

class ChatViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate{
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatTableView: UITableView!
    
    var channel: Channel?
    var twitchChatClient : TwitchChatClient = TwitchChatClient()
    
    var messages = [Message]()
    var maxMessages = 100
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendButton.isHidden = true
        configureTableView()
        configureTextField()
        self.twitchChatClient.setChannel(channel: self.channel!)
        LoadingIndicatorView.show(self.view)
        DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
            self.twitchChatClient.start()
            DispatchQueue.main.async {
                LoadingIndicatorView.hide()
            }
        }
        
        timer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(self.updateTable), userInfo: nil, repeats: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        twitchChatClient.stop()
    }
    
    func updateTable(){
        self.chatTableView.beginUpdates()
        removeOldMessages()
        addNewMessages()
        self.chatTableView.endUpdates()
    }
    
    func removeOldMessages(){
        let messagesToRemove = messages.count - maxMessages
        if messagesToRemove > 0{
            var indexPaths = [IndexPath]()
            DispatchQueue.main.async {
                self.messages.removeFirst(messagesToRemove)
                for i in 0..<messagesToRemove{
                    indexPaths.append(IndexPath(row: i, section: 0))
                }
                self.chatTableView.deleteRows(at: indexPaths, with: UITableViewRowAnimation.none)
            }
        }
    }
    
    func addNewMessages(){
        let newMessages = twitchChatClient.getMessages()
        if newMessages.count > 0{
            var indexPaths = [IndexPath]()
            DispatchQueue.main.async {
                for message in newMessages {
                    indexPaths.append(IndexPath(row: self.messages.count, section: 0))
                    self.messages.append(message)
                }
                self.chatTableView.insertRows(at: indexPaths, with: UITableViewRowAnimation.none)
                self.chatTableView.scrollToRow(at: indexPaths.last!, at: .bottom, animated: false)
            }
        }
    }
    
    func stop(){
        self.twitchChatClient.stop()
        self.timer?.invalidate()
    }
    
    func configureTextField(){
        messageTextField.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func configureTableView(){
        chatTableView.delegate = self
        chatTableView.dataSource = self
        chatTableView.rowHeight = UITableViewAutomaticDimension
        chatTableView.estimatedRowHeight = 23.5
    }
    
    @IBAction func sendButtonPressed(_ sender: UIButton) {
        if let message = messageTextField.text{
            if(message != ""){
                messageTextField.text = ""
                messageTextField.endEditing(true)
                sendButton.isHidden = true
                DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
                    self.twitchChatClient.sendMessage(string: message)
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let index = indexPath.row
        messages[index].dynamicHeight = cell.frame.size.height
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let index = indexPath.row
        return messages[index].dynamicHeight
    }
    
    deinit {
        print("chatviewcontrollerdeinit")
    }
}

extension ChatViewController: UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
        
        let index = indexPath.row
        
        cell.messageLabel.attributedText = messages[index].nsAttributedString
        
        return cell
    }
}
