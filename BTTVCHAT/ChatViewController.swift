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
//chat doest start at the top

import UIKit

class ChatViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate{
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatTableView: ChatUITableView!
    
    var channel: Channel?
    var twitchChatClient : TwitchChatClient = TwitchChatClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sendButton.isHidden = true
        configureTableView()
        configureTextField()
        self.twitchChatClient.setChannel(channel: self.channel!)
        LoadingIndicatorView.show(self.view)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
            self.twitchChatClient.start()
            DispatchQueue.main.async {
                LoadingIndicatorView.hide()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTable), name: NSNotification.Name(rawValue: "newMessage"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        twitchChatClient.stop()
    }
    
    func reloadTable(){
        chatTableView.startSticktoBottom()
        DispatchQueue.main.async {
            self.chatTableView.reloadData()
        }
    }
    
    func stop(){
        self.twitchChatClient.stop()
    }
    
    func configureTextField(){
        messageTextField.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func configureTableView(){
        chatTableView.delegate = self
        chatTableView.dataSource = twitchChatClient
        chatTableView.rowHeight = UITableViewAutomaticDimension
        chatTableView.estimatedRowHeight = 44
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
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        chatTableView.atBottom = false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if maximumOffset - currentOffset <= 30.0 {
            chatTableView.atBottom = true
        }else{
            chatTableView.atBottom = false
        }
    }
}
