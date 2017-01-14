//
//  BadgesController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/1/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class BadgeController: NSObject {
    
    var channel: Channel?
    let globalBadgesAPIString = "https://badges.twitch.tv/v1/badges/global/display?language=en"
    var channelBadgesAPIURLString: String?
    
    let semaphore = DispatchSemaphore(value: 0)
    var badgeTrie = Trie<Badge>()
    
    init(channel: Channel){
        super.init()
        self.channel = channel
        channelBadgesAPIURLString = "https://badges.twitch.tv/v1/badges/channels/\(channel.id)/display?language=en"
        getGlobalBadges()
        semaphore.wait()
        getChannelBadges()
        semaphore.wait()
    }
    
    func getBadgeImage(badgeName: String) -> UIImage?{        
        var badgeImage: UIImage?
        
        if let badge = badgeTrie.search(key: badgeName){
            if let image = ImageCache.getImage(key: badge.urlString){
                badgeImage = image
            }else{
                if let url = URL(string: badge.urlString){
                    let session = URLSession.shared
                    
                    session.dataTask(with: url ){ data, response, err in
                        if err == nil{
                            if let newData = data, let image = UIImage(data: newData){
                                badgeImage = image
                                ImageCache.setImage(key: badge.urlString, value: image)
                            }
                        }else{
                            print("downloadImage: \(err?.localizedDescription)")
                        }
                        self.semaphore.signal()
                    }.resume()
                
                    semaphore.wait()
                }
            }
        }
        
        return badgeImage
    }
    
    func getGlobalBadges(){
        if let badgesAPIURL = URL(string: globalBadgesAPIString) {
            
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
                                                    let badge = Badge(name: "\(badge)/\(badgeversion)", urlString: imageurl1x)
                                                    self.badgeTrie.insert(key: badge.name, value: badge)
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
                self.semaphore.signal()
            }.resume()
        }
    }
    
    func getChannelBadges(){
        if let badgesAPIURL = URL(string: channelBadgesAPIURLString!) {
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
                                                    let badge = Badge(name: "\(badge)/\(badgeversion)", urlString: imageurl1x)
                                                    self.badgeTrie.insert(key: badge.name, value: badge)
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
                self.semaphore.signal()
            }.resume()
        }
    }
}
