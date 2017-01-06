//
//  EmoteController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/2/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class EmoteController: NSObject {
    
    var channel: Channel?
    let bttvGlobalEmotesAPIString = "https://api.betterttv.net/2/emotes"
    var bttvChannelEmotesAPIString : String?
    let apisema = DispatchSemaphore(value: 0)
    
    var bttvURLTemplate : String?
    var bttvEmoteDictionary = [String: bttvEmote]()
    
    let emotesURL = "http://static-cdn.jtvnw.net/emoticons/v1/{{id}}/1.0"
    
    init(channel: Channel){
        super.init()
        self.channel = channel
        bttvChannelEmotesAPIString = "https://api.betterttv.net/2/channels/\(channel.name)"
        self.getGlobalBTTVEmotesId()
        self.getChannelBTTVEmotesId()
        apisema.wait()
        apisema.wait()
    }
    
    func getEmoteImage(emote: Emote) -> UIImage?{
        var emoteImage: UIImage?
        
        if emote.better {
            if let bttvEmote = bttvEmoteDictionary[emote.emoteText]{
                if let urlString = bttvURLTemplate?.replacingOccurrences(of: "{{id}}", with: bttvEmote.emoteID){
                    if let image = ImageCache.getImage(key: urlString){
                        emoteImage = image
                    }else{
                        if let image = downloadImage(urlString: urlString){
                            emoteImage = image
                            ImageCache.setImage(key: urlString, value: emoteImage!)
                        }
                    }
                }
            }
        }else{
            let urlString = emotesURL.replacingOccurrences(of: "{{id}}", with: emote.emoteID)
            
            if let image = ImageCache.getImage(key: urlString){
                emoteImage = image
            }else{
                if let image = downloadImage(urlString: urlString){
                    emoteImage = image
                    ImageCache.setImage(key: urlString, value: emoteImage!)
                }
            }
        }
        
        return emoteImage
    }
    
    func downloadImage(urlString: String) -> UIImage?{
        var image : UIImage?
        if let url = URL(string: urlString){
            let session = URLSession.shared
            session.dataTask(with: url){ data, response, err in
                if err == nil{
                    if let newData = data, let newImage = UIImage(data: newData){
                        image = newImage
                    }
                }else{
                    print("downloadImage: \(err?.localizedDescription)")
                }
                self.apisema.signal()
            }.resume()
            
            apisema.wait()
        }
        return image
    }
    
    func getGlobalBTTVEmotesId(){
        if let emotesAPIURL = URL(string: bttvGlobalEmotesAPIString) {
            
            var request = URLRequest(url: emotesAPIURL )
            request.httpMethod = "GET"
            
            let session = URLSession.shared
            
            session.dataTask(with: request){ data, response, err in
                if err == nil{
                    if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: [])
                            
                            if let dictionary = json as? [String: Any], let urlTemplate = dictionary["urlTemplate"] as? String{
                                
                                var newUrlTemplate = "https:"
                                newUrlTemplate.append(urlTemplate.replacingOccurrences(of: "{{image}}", with: "1x"))
                                self.bttvURLTemplate = newUrlTemplate
                                
                                if let emotes = dictionary["emotes"] as? [[String:Any]]{
                                    for emote in emotes{
                                        if let _ = emote["channel"] as? String {
                                            
                                        }else{
                                            if let id = emote["id"] as? String, let code = emote["code"] as? String, let imageType = emote["imageType"] as? String {
                                                self.bttvEmoteDictionary[code] = bttvEmote(emoteID: id, emoteText: code, emoteType: imageType)
                                            }
                                        }
                                        
                                    }
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
                self.apisema.signal()
            }.resume()
        }
    }
    
    func getChannelBTTVEmotesId(){
        if let emotesAPIURL = URL(string: bttvChannelEmotesAPIString!){
            
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
                                        if let BTTVChannel = emote["channel"] as? String, BTTVChannel == self.channel!.name {
                                            if let id = emote["id"] as? String, let code = emote["code"] as? String, let imageType = emote["imageType"] as? String {
                                                self.bttvEmoteDictionary[code] = bttvEmote(emoteID: id, emoteText: code, emoteType: imageType)
                                            }
                                        }
                                    }
                                    
                                }
                                
                            }
                        } catch let error as NSError {
                            print("Failed to load: \(error.localizedDescription)")
                        }
                        
                    }
                    print("got channel bttv emote id")
                }else{
                    print("getBadges: \(err?.localizedDescription)")
                }
                self.apisema.signal()
            }.resume()
        }
    }
    
    func createEmotes(message: Message){
        checkEmotes(message: message)
        checkBTTVEmotes(message: message)
        sortEmotes(message: message)
    }
    
    func checkEmotes(message: Message){
        let differentEmotes = message.emoteString.components(separatedBy: "/").filter{!$0.isEmpty}
        
        for emote in differentEmotes {
            let emoteIDIndexs = emote.components(separatedBy: CharacterSet(charactersIn: ":-,")).filter{!$0.isEmpty}
            let emoteID = emoteIDIndexs[0]
            
            for i in stride(from: 1, to: emoteIDIndexs.count, by: 2){
                if let startIndex = Int(emoteIDIndexs[i]), let endIndex = Int(emoteIDIndexs[i + 1]){
                    message.emotes.append(Emote(emoteID: emoteID, emoteText: "", startIndex: startIndex, length: endIndex - startIndex + 1, better: false, imageType: "png"))
                }
            }
        }
    }
    
    func checkBTTVEmotes(message: Message){
        let words = message.message.components(separatedBy: " ")
        var startIndex = 0
            
        for word in words{
            if let bttvEmote = bttvEmoteDictionary[word], bttvEmote.emoteType != "gif" {
                message.emotes.append(Emote(emoteID: bttvEmote.emoteID, emoteText: word, startIndex: startIndex, length: word.characters.count, better: true, imageType: bttvEmote.emoteType))
            }
            startIndex += word.characters.count + 1
        }
    }
    
    func sortEmotes(message: Message){
        message.emotes.sort(by: {$0.startIndex < $1.startIndex})
    }
}
