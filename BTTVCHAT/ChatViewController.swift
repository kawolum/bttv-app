//
//  ViewController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/3/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatTableView: UITableView!
    
    var maxMessageCount = 200
    
    var messages = [Message]()
    var badges = [String: String]()
    var badgeImages = [String : UIImage]()
    var images = [String : UIImage]()
    var bttvEmoteId = [String: String]()
    var bttvEmoteUrlTemplate: String?

    let client:TCPClient = TCPClient(addr: "irc.chat.twitch.tv", port: 6667)
    var pass: String? = "oauth:3jzkmsisl13cls2529jezdrl20xqdk"
    var nick: String? = "kawolum822"
    var channel: String? = "kawolum822"
    var headerAcceptKey = "Accept"
    var headerAcceptValue = "application/vnd.twitchtv.v5+json"
    var headerClientIDKey = "Client-ID"
    var headerClientIDValue = "3jrodo343bfqtrfs2y0nnxfnn0557j0"
    
    var twitchChatClient = TwitchChatClient(channel: "meteos")
    
    var nsAttributedString = [NSAttributedString]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chatTableView.delegate = self
        chatTableView.dataSource = self
        configureTextField()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getStuff()
        self.twitchChatClient.start()
        self.getMessages()
        
    }
    
    func complete(bool: Bool){
        print(bool)
    }
    
    func getStuff(){
        self.getGlobalBadges(){
            self.getChannelBadges()
        }
        self.getGlobalBTTVEmotesId()
        self.getChannelBTTVEmotesId()
    }
    
    func getMessages(){
        DispatchQueue.global(qos: DispatchQoS.userInitiated.qosClass).async {
            while(true){
                if let message = self.twitchChatClient.pop(){
                    print(message.message)
                        self.downloadRequiredBadges(badges: message.badges!){
                            self.nsAttributedString.append(self.makeAttributedString(message: message))
                            DispatchQueue.main.async{
                            
                                self.chatTableView.reloadData()
                            }
                        }
                    
                }
            }
        }
    }
    
    func configureTextField(){
        messageTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func appendMessageToTableView(message:Message){
        DispatchQueue.main.async{
            
            self.messages.append(message)
            let bottomIndexPath = IndexPath(row: (self.messages.count - 1), section: 0)
            UIView.setAnimationsEnabled(false)
            
            self.chatTableView.insertRows(at: [bottomIndexPath], with: UITableViewRowAnimation.none)
            
            self.chatTableView.scrollToRow(at: bottomIndexPath, at: UITableViewScrollPosition.bottom, animated: false)
            
            if(self.messages.count > self.maxMessageCount){
                
                self.messages.removeFirst()
                let topIndexPath = IndexPath(row: 0, section: 0)
                self.chatTableView.deleteRows(at: [topIndexPath], with: UITableViewRowAnimation.none)
            }
            UIView.setAnimationsEnabled(true)
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nsAttributedString.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        
        let index = indexPath.row
        
        cell.textLabel?.attributedText = nsAttributedString[index]
        
        return cell
    }
    
    func makeAttributedString(message:Message) -> NSAttributedString {
        let words = message.message.components(separatedBy: " ")
        var currentbttvIndex = 0
        
        for word in words{
            if isBTTVEmote(word: word){
                message.emotes.append(Emote(emoteID: word, startIndex: currentbttvIndex, length: word.characters.count - 1, better: true))
            }
            currentbttvIndex += word.characters.count + 1
        }
        message.emotes.sort(by: {$0.startIndex < $1.startIndex})
        
        let finalString = NSMutableAttributedString()
        
        if let badges = message.badges{
            for badge in badges{
                if let badgeImage = badgeImages[badge]{
                    let badgeAttachment = NSTextAttachment()
                    badgeAttachment.image = badgeImage
                    
                    let badgeString = NSAttributedString(attachment: badgeAttachment)
                    
                    finalString.append(badgeString)
                }else{
                    if let stringurl = self.badges[badge], let uRL = URL(string: stringurl) {
                        downloadImage(url: uRL){ (badgeImage) in
                            self.badgeImages[badge] = badgeImage
                            let badgeAttachment = NSTextAttachment()
                            badgeAttachment.image = badgeImage
                            let badgeString = NSAttributedString(attachment: badgeAttachment)
                            finalString.append(badgeString)

                        }
                    }
                    
                }
            }
        }
        
        let displayNameAttributes = [NSForegroundColorAttributeName: hexStringToUIColor(hex:message.color)]
        let displayNameString = NSMutableAttributedString(string: message.displayName, attributes: displayNameAttributes)
        finalString.append(displayNameString)

        finalString.append(NSAttributedString(string: ": "))
        
        var currentIndex = 0;
        var currentString = ""
        var skip = 0;
        
        for index in message.message.characters.indices{
            if skip > 0{
                skip -= 1
            }else{
                if message.emotes.count > 0, currentIndex == message.emotes[0].startIndex{
                    finalString.append(NSAttributedString(string: currentString))
                    currentString = ""
                    
                    if let emote = images[message.emotes[0].emoteID]{
                        print("in array")
                        
                        let emoteAttachment = NSTextAttachment()
                        emoteAttachment.image = emote
                        
                        let emoteString = NSAttributedString(attachment: emoteAttachment)
                        
                        finalString.append(emoteString)
                    }else{
                        if message.emotes[0].better {
                            getBTTVEmote(emoteCode: message.emotes[0].emoteID)
                        }else{
                            print(message.emotes[0].emoteID)
                            getEmote(emoteid: message.emotes[0].emoteID)
                        }
                    }
                    skip = message.emotes[0].length
                    message.emotes.removeFirst()
                    
                    
                }else{
                    currentString.append(message.message[index])
                }
            }
            
            currentIndex += 1
            
        }
        
        if currentString != "" {
            finalString.append(NSAttributedString(string: currentString))
        }
        return finalString
    }
    
    func downloadRequiredBadges(badges : [String], completion: @escaping() -> Void){
        print(badges)
        
        let group = DispatchGroup()
        
        for badge in badges{
            if badgeImages[badge] == nil{
                group.enter()
                if let stringurl = self.badges[badge], let uRL = URL(string: stringurl) {
                    downloadImage(url: uRL){ (badgeImage) in
                        self.badgeImages[badge] = badgeImage
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass)){
            completion()
        }
    }
    
    func isBTTVEmote(word: String) -> Bool{
        if bttvEmoteId[word] != nil{
            return true
        }
        return false
    }
    
    func getGlobalBadges(completion: @escaping () -> Void){
        
        let badgesAPIURLString = "https://badges.twitch.tv/v1/badges/global/display?language=en"
        
        
        if let badgesAPIURL = URL(string: badgesAPIURLString) {
            
            var request = URLRequest(url: badgesAPIURL )
            request.httpMethod = "GET"
            
            let session = URLSession.shared
        
            session.dataTask(with: request){ data, response, err in
                if err == nil{
                    if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: [])
                            
                            if let dictionary = json as? [String: Any], let badgesets = dictionary["badge_sets"] as? [String: Any]{
                                for (key, value) in badgesets{
                                    
                                    let badge = key
                                    if let versions = value as? [String: Any], let newVersions = versions["versions"] as? [String: Any]{
                                        for (key, value) in newVersions{
                                            
                                            let badgeversion = key
                                            if let details = value as? [String: Any]{
                                                if let imageurl1x = details["image_url_1x"] as? String {
                                                    self.badges["\(badge)/\(badgeversion)"] = imageurl1x
                                                    print("\(badge)/\(badgeversion)")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        } catch let error as NSError {
                            print("Failed to load: \(error.localizedDescription)")
                        }
                        
                    }
                }else{
                    print("getBadges: \(err?.localizedDescription)")
                }
                
                completion()
            }.resume()
        }
    }
    
    func getChannelBadges(){
        let badgesAPIURLString = "https://badges.twitch.tv/v1/badges/channels/51496027/display?language=en"
        
        if let badgesAPIURL = URL(string: badgesAPIURLString) {
            
            var request = URLRequest(url: badgesAPIURL )
            request.httpMethod = "GET"
            
            let session = URLSession.shared
            
            session.dataTask(with: request){ data, response, err in
                if err == nil{
                    if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
                        do {
                            
                            let json = try JSONSerialization.jsonObject(with: data!, options: [])
                            
                            if let dictionary = json as? [String: Any], let badgesets = dictionary["badge_sets"] as? [String: Any]{
                                for (key, value) in badgesets{
                                    
                                    let badge = key
                                    if let versions = value as? [String: Any], let newVersions = versions["versions"] as? [String: Any]{
                                        for (key, value) in newVersions{
                                            
                                            let badgeversion = key
                                            if let details = value as? [String: Any]{
                                                if let imageurl1x = details["image_url_1x"] as? String {
                                                    self.badges["\(badge)/\(badgeversion)"] = imageurl1x
                                                    print("\(badge)/\(badgeversion)")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        } catch let error as NSError {
                            print("Failed to load: \(error.localizedDescription)")
                        }
                        
                    }
                }else{
                    print("getBadges: \(err?.localizedDescription)")
                }
            }.resume()
        }
    }
    
    func getGlobalBTTVEmotesId(){
        let emotesAPIURLString = "https://api.betterttv.net/2/emotes"
        
        if let emotesAPIURL = URL(string: emotesAPIURLString) {
            
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
                                self.bttvEmoteUrlTemplate = newUrlTemplate
                                
                                if let emotes = dictionary["emotes"] as? [[String:Any]]{
                                    for emote in emotes{
                                        if let _ = emote["channel"] as? String {
                                            
                                        }else{
                                            if let id = emote["id"] as? String, let code = emote["code"] as? String {
                                                self.bttvEmoteId[code] = id
                                            }
                                        }
                                        
                                    }
                                }
                            }
                        } catch let error as NSError {
                            print("Failed to load: \(error.localizedDescription)")
                        }
                        
                    }
                    print("got general bttv emote id")
                }else{
                    print("getBadges: \(err?.localizedDescription)")
                }
            }.resume()
        }
    }
    
    func getChannelBTTVEmotesId(){
        let emotesAPIURLString = "https://api.betterttv.net/2/channels/\(channel!)"
        
        if let emotesAPIURL = URL(string: emotesAPIURLString){
            
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
                                                self.bttvEmoteId[code] = id
                                            }
                                        }
                                        
                                    }
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
        }
    }
    
    func getBTTVEmote(emoteCode: String){
        if var urlstring = bttvEmoteUrlTemplate, let emoteid = bttvEmoteId[emoteCode]{
            urlstring = urlstring.replacingOccurrences(of: "{{id}}", with: emoteid)
            
            if let url = URL(string: urlstring){
                //self.downloadImage(url: url, key: emoteCode)
            }
        }
    }
    
    func getEmote(emoteid: String){
        
        let emotesURL = "http://static-cdn.jtvnw.net/emoticons/v1/\(emoteid)/1.0"
        
        if let url = URL(string: emotesURL) {
            //self.downloadImage(url: url, key: emoteid)
        }
    }
    
    func downloadImage(url : URL, completion: @escaping(UIImage) -> Void) {
        let session = URLSession.shared
        
        session.dataTask(with: url ){ data, response, err in
            if err == nil{
                if let newData = data, let newImage = UIImage(data: newData){
                    print(url)
                    completion(newImage)
                }
            }else{
                print("downloadImage: \(err?.localizedDescription)")
            }
        }.resume()
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
