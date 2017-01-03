//
//  BadgesController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/1/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class BadgeController: NSObject {
    
    let globalBadgesAPIString = "https://badges.twitch.tv/v1/badges/global/display?language=en"
    let channelBadgesAPIURLString = "https://badges.twitch.tv/v1/badges/channels/51496027/display?language=en"//need to replace the channel id
    
    var badges = [String : Badge]()
    var channel: String?
    
    let apisema = DispatchSemaphore(value: 0)
    
    init(channel: String){
        super.init()
        self.channel = channel
        getGlobalBadges()
        getChannelBadges()
        apisema.wait()
        apisema.wait()
    }
    
    func getBadgeImage(badgeName: String) -> UIImage?{        
        var badgeImage: UIImage?
        
        if let badge = badges[badgeName]{
            if let image = ImageCache.getImage(key: badge.badgeURLString){
                badgeImage = image
            }else{
                if let url = URL(string: badge.badgeURLString){
                    let session = URLSession.shared
                    
                    session.dataTask(with: url ){ data, response, err in
                        if err == nil{
                            if let newData = data, let image = UIImage(data: newData){
                                badgeImage = image
                                ImageCache.setImage(key: badge.badgeURLString,value: image)
                            }
                        }else{
                            print("downloadImage: \(err?.localizedDescription)")
                        }
                        self.apisema.signal()
                    }.resume()
                
                    apisema.wait()
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
                                                    self.badges["\(badge)/\(badgeversion)"] = Badge(badgeName: "\(badge)/\(badgeversion)", badgeURLString: imageurl1x)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        } catch let error as NSError {
                            print("Failed to load: \(error.localizedDescription)")
                        }
                        print("got global badges")
                    }
                }else{
                    print("getBadges: \(err?.localizedDescription)")
                }
                self.apisema.signal()
            }.resume()
        }
    }
    
    func getChannelBadges(){
        if let badgesAPIURL = URL(string: channelBadgesAPIURLString) {
            
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
                                                    self.badges["\(badge)/\(badgeversion)"] = Badge(badgeName: "\(badge)/\(badgeversion)", badgeURLString: imageurl1x)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        } catch let error as NSError {
                            print("Failed to load: \(error.localizedDescription)")
                        }
                        print("got channel badges")
                    }
                }else{
                    print("getBadges: \(err?.localizedDescription)")
                }
                self.apisema.signal()
            }.resume()
        }
    }
}
