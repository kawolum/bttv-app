//
//  BadgesController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/1/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class BadgesController: NSObject {
    
//    var badges: [String : Badge]
//    
//    override init(){
//    }
//    
//    func getGlobalBadges(completion: @escaping () -> Void){
//        
//        let badgesAPIURLString = "https://badges.twitch.tv/v1/badges/global/display?language=en"
//        
//        
//        if let badgesAPIURL = URL(string: badgesAPIURLString) {
//            
//            var request = URLRequest(url: badgesAPIURL )
//            request.httpMethod = "GET"
//            
//            let session = URLSession.shared
//            
//            session.dataTask(with: request){ data, response, err in
//                if err == nil{
//                    if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
//                        do {
//                            let json = try JSONSerialization.jsonObject(with: data!, options: [])
//                            
//                            if let dictionary = json as? [String: Any], let badgesets = dictionary["badge_sets"] as? [String: Any]{
//                                for (key, value) in badgesets{
//                                    
//                                    let badge = key
//                                    if let versions = value as? [String: Any], let newVersions = versions["versions"] as? [String: Any]{
//                                        for (key, value) in newVersions{
//                                            
//                                            let badgeversion = key
//                                            if let details = value as? [String: Any]{
//                                                if let imageurl1x = details["image_url_1x"] as? String {
//                                                    self.badges["\(badge)/\(badgeversion)"] = imageurl1x
//                                                    print("\(badge)/\(badgeversion)")
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                            
//                        } catch let error as NSError {
//                            print("Failed to load: \(error.localizedDescription)")
//                        }
//                        
//                    }
//                }else{
//                    print("getBadges: \(err?.localizedDescription)")
//                }
//                
//                completion()
//                }.resume()
//        }
//    }
//    
//    func getChannelBadges(){
//        let badgesAPIURLString = "https://badges.twitch.tv/v1/badges/channels/51496027/display?language=en"
//        
//        if let badgesAPIURL = URL(string: badgesAPIURLString) {
//            
//            var request = URLRequest(url: badgesAPIURL )
//            request.httpMethod = "GET"
//            
//            let session = URLSession.shared
//            
//            session.dataTask(with: request){ data, response, err in
//                if err == nil{
//                    if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
//                        do {
//                            
//                            let json = try JSONSerialization.jsonObject(with: data!, options: [])
//                            
//                            if let dictionary = json as? [String: Any], let badgesets = dictionary["badge_sets"] as? [String: Any]{
//                                for (key, value) in badgesets{
//                                    
//                                    let badge = key
//                                    if let versions = value as? [String: Any], let newVersions = versions["versions"] as? [String: Any]{
//                                        for (key, value) in newVersions{
//                                            
//                                            let badgeversion = key
//                                            if let details = value as? [String: Any]{
//                                                if let imageurl1x = details["image_url_1x"] as? String {
//                                                    self.badges["\(badge)/\(badgeversion)"] = imageurl1x
//                                                    print("\(badge)/\(badgeversion)")
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                            
//                        } catch let error as NSError {
//                            print("Failed to load: \(error.localizedDescription)")
//                        }
//                        
//                    }
//                }else{
//                    print("getBadges: \(err?.localizedDescription)")
//                }
//            }.resume()
//        }
//    }
}
