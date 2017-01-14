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
    let tEmoteURLString = "http://static-cdn.jtvnw.net/emoticons/v1/{{id}}/1.0"
    var bEmoteURLString : String?
    let bGlobalEmotesAPIURLString = "https://api.betterttv.net/2/emotes"
    var bChannelEmotesAPIURLString : String?
    
    let semaphore = DispatchSemaphore(value: 0)
    
    var bEmoteTrie = Trie<Emote>()
    
    init(channel: Channel){
        super.init()
        self.channel = channel
        bChannelEmotesAPIURLString = "https://api.betterttv.net/2/channels/\(channel.name)"
        self.getGlobalBTTVEmotesId()
        self.getChannelBTTVEmotesId()
        semaphore.wait()
        semaphore.wait()
    }
    
    func getEmoteImage(emote: MessageEmote) -> UIImage?{
        var emoteImage: UIImage?
        var urlString: String?
        if emote.better {
            urlString = bEmoteURLString?.replacingOccurrences(of: "{{id}}", with: emote.id)
        }else{
            urlString = tEmoteURLString.replacingOccurrences(of: "{{id}}", with: emote.id)
        }
        if urlString != nil{
            if let image = ImageCache.getImage(key: urlString!){
                emoteImage = image
            }else{
                if let image = downloadImage(urlString: urlString!){
                    ImageCache.setImage(key: urlString!, value: image)
                    emoteImage = image
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
                self.semaphore.signal()
            }.resume()
            semaphore.wait()
        }
        return image
    }
    
    func getGlobalBTTVEmotesId(){
        if let emotesAPIURL = URL(string: bGlobalEmotesAPIURLString) {
            
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
                                self.bEmoteURLString = newUrlTemplate
                                
                                if let emotes = dictionary["emotes"] as? [[String:Any]]{
                                    for emote in emotes{
                                        if let _ = emote["channel"] as? String {
                                            
                                        }else{
                                            if let id = emote["id"] as? String, let text = emote["code"] as? String, let type = emote["imageType"] as? String {
                                                self.bEmoteTrie.insert(key: text, value: Emote(id: id, text: text, better: true, type: type))
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
                self.semaphore.signal()
            }.resume()
        }
    }
    
    func getChannelBTTVEmotesId(){
        if let emotesAPIURL = URL(string: bChannelEmotesAPIURLString!){
            
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
                                            if let id = emote["id"] as? String, let text = emote["code"] as? String, let type = emote["imageType"] as? String {
                                                self.bEmoteTrie.insert(key: text, value: Emote(id: id, text: text, better: true, type: type))
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
                self.semaphore.signal()
            }.resume()
        }
    }
    
    func createEmotes(message: Message){
        parseEmoteString(message: message)
        checkBTTVEmotes(message: message)
        sortEmotes(message: message)
    }
    
    func parseEmoteString(message: Message){
        let differentEmotes = message.emoteString.components(separatedBy: "/").filter{!$0.isEmpty}
        
        for emote in differentEmotes {
            let emoteIDIndexs = emote.components(separatedBy: CharacterSet(charactersIn: ":-,")).filter{!$0.isEmpty}
            let emoteID = emoteIDIndexs[0]
            
            for i in stride(from: 1, to: emoteIDIndexs.count, by: 2){
                if let startIndex = Int(emoteIDIndexs[i]), let endIndex = Int(emoteIDIndexs[i + 1]){
                    let messageEmote = MessageEmote(id: emoteID, text: "", better: false, type: "png", startIndex: startIndex, length: endIndex - startIndex + 1)
                    message.messageEmotes.append(messageEmote)
                }
            }
        }
    }
    
    func checkBTTVEmotes(message: Message){
        let words = message.message.components(separatedBy: " ")
        var wordIndex = 0
        var tEmoteIndex = -1
        var tEmotesIndex = 0
        
        for word in words{
            while(message.messageEmotes.count > tEmotesIndex && tEmoteIndex < wordIndex){
                tEmoteIndex = message.messageEmotes[tEmotesIndex].startIndex
                tEmotesIndex += 1
            }
            
            if tEmoteIndex != wordIndex, let bEmote = bEmoteTrie.search(key: word), bEmote.type != "gif" {
                let messageEmote = MessageEmote(id: bEmote.id, text: bEmote.text, better: true, type: bEmote.type, startIndex: wordIndex, length: word.characters.count)
                message.messageEmotes.append(messageEmote)
            }
            wordIndex += word.characters.count + 1
        }
    }
    
    func sortEmotes(message: Message){
        message.messageEmotes.sort(by: {$0.startIndex < $1.startIndex})
    }
}
