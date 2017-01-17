//
//  TwitchAPIManager.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/7/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit
import Locksmith

class TwitchAPIManager{
    static let sharedInstance = TwitchAPIManager()
    
    let oAuthURL = "https://api.twitch.tv/kraken/oauth2/authorize?response_type=token&client_id=3jrodo343bfqtrfs2y0nnxfnn0557j0&redirect_uri=kawobttvchat://&scope=user_read+chat_login"
    let usernameAPIURLString = "https://api.twitch.tv/kraken"
    
    var oAuthToken: String?{
        set{
            if let valueToSave = newValue{
                if var dictionary = Locksmith.loadDataForUserAccount(userAccount: "bttvchat"){
                    dictionary["token"] = newValue
                    do{
                        try Locksmith.updateData(data: dictionary, forUserAccount: "bttvchat")
                    }catch{
                        print(error)
                    }
                }else{
                    do{
                        try Locksmith.saveData(data: ["token": valueToSave], forUserAccount: "bttvchat")
                    }catch{
                        do {
                            try Locksmith.deleteDataForUserAccount(userAccount: "bttvchat")
                        }catch{
                            print(error)
                        }
                    }
                }
            }else{
                do {
                    try Locksmith.deleteDataForUserAccount(userAccount: "bttvchat")
                }catch{
                    print(error)
                }
            }
        }
        get{
            if let dictionary = Locksmith.loadDataForUserAccount(userAccount: "bttvchat"){
                if let token = dictionary["token"] as? String{
                    return token
                }
            }
            
            return nil
        }
    }
    
    var username: String?{
        set{
            if let valueToSave = newValue{
                if var dictionary = Locksmith.loadDataForUserAccount(userAccount: "bttvchat"){
                    dictionary["username"] = newValue
                    do{
                        try Locksmith.updateData(data: dictionary, forUserAccount: "bttvchat")
                    }catch{
                        print(error)
                    }
                }else{
                    do{
                        try Locksmith.saveData(data: ["username": valueToSave], forUserAccount: "bttvchat")
                    }catch{
                        do {
                            try Locksmith.deleteDataForUserAccount(userAccount: "bttvchat")
                        }catch{
                            print(error)
                        }
                    }
                }
            }else{
                do {
                    try Locksmith.deleteDataForUserAccount(userAccount: "bttvchat")
                }catch{
                    print(error)
                }
            }
        }
        get{
            if let dictionary = Locksmith.loadDataForUserAccount(userAccount: "bttvchat"){
                if let token = dictionary["username"] as? String{
                    return token
                }
            }
            
            return nil
        }
    }
    
    var userID: String?{
        set{
            if let valueToSave = newValue{
                if var dictionary = Locksmith.loadDataForUserAccount(userAccount: "bttvchat"){
                    dictionary["userID"] = newValue
                    do{
                        try Locksmith.updateData(data: dictionary, forUserAccount: "bttvchat")
                    }catch{
                        print(error)
                    }
                }else{
                    do{
                        try Locksmith.saveData(data: ["userID": valueToSave], forUserAccount: "bttvchat")
                    }catch{
                        do {
                            try Locksmith.deleteDataForUserAccount(userAccount: "bttvchat")
                        }catch{
                            print(error)
                        }
                    }
                }
            }else{
                do {
                    try Locksmith.deleteDataForUserAccount(userAccount: "bttvchat")
                }catch{
                    print(error)
                }
            }
        }
        get{
            if let dictionary = Locksmith.loadDataForUserAccount(userAccount: "bttvchat"){
                if let token = dictionary["userID"] as? String{
                    return token
                }
            }
            
            return nil
        }
    }
    
    var oAuthTokenCompletionHandler : ((NSError?) -> Void)?
    let clientIDHeader = "Client-ID"
    let clientIDValue = "3jrodo343bfqtrfs2y0nnxfnn0557j0"
    let acceptHeader = "Accept"
    let acceptValue = "application/vnd.twitchtv.v5+json"
    let authorizationHeader = "Authorization"
    let authorizationValue = "OAuth "
    
    
    func hasOAuthToken() -> Bool{
        return oAuthToken != nil && !oAuthToken!.isEmpty;
    }
    
    func startOAuth2Login(completion: @escaping (NSError?) -> Void){
        self.oAuthTokenCompletionHandler = completion
        if let url = URL(string: oAuthURL){
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: "loadingOAuthToken")
            
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func processOAuthResponse(url: URL){
        if let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let fragments = components.fragment{
                let pairs = fragments.components(separatedBy: "&")
                for pair in pairs{
                    let keyValue = pair.components(separatedBy: "=")
                    if keyValue.count > 1, keyValue[0] == "access_token"{
                        oAuthToken = keyValue[1]
                        break;
                    }
                }
            }
        }
        if hasOAuthToken() {
            getUsername()
        }else{
            let defaults = UserDefaults.standard
            defaults.set(false, forKey: "loadingOAuthToken")
            
            if let completionHandler = self.oAuthTokenCompletionHandler {
                let error = NSError(domain: "OAuth error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not obtain an OAuth token", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
                completionHandler(error)
            }
            self.oAuthTokenCompletionHandler = nil
        }
    }
    
    func getUsername() {
        if let usernameAPIURL = URL(string: usernameAPIURLString) {
            
            var request = URLRequest(url: usernameAPIURL )
            request.httpMethod = "GET"
            request.addValue(clientIDValue, forHTTPHeaderField: clientIDHeader)
            request.addValue(acceptValue, forHTTPHeaderField: acceptHeader)
            request.addValue("\(authorizationValue)\(oAuthToken!)", forHTTPHeaderField: authorizationHeader)
            
            let session = URLSession.shared
            
            session.dataTask(with: request){ data, response, err in
                if err == nil{
                    if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: [])
                            
                            if let dictionary = json as? [String: Any], let token = dictionary["token"] as? [String: Any], let username = token["user_name"] as? String, let userID = token["user_id"] as? String{
                                
                                self.username = username
                                self.userID = userID
                                
                                let defaults = UserDefaults.standard
                                defaults.set(false, forKey: "loadingOAuthToken")

                                if let completionHandler = self.oAuthTokenCompletionHandler
                                {
                                    completionHandler(nil)
                                }
                                self.oAuthTokenCompletionHandler = nil

                            }
                            
                        } catch let error as NSError {
                            print("Failed to load: \(error.localizedDescription)")
                        }
                    }
                }else{
                    print("getUsername: \(err?.localizedDescription)")
                }
                
                let defaults = UserDefaults.standard
                defaults.set(false, forKey: "loadingOAuthToken")
            }.resume()
        }
    }
}
