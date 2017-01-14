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
    var oAuthToken: String?{
        set{
            if let valueToSave = newValue{
                do{
                    try Locksmith.saveData(data: ["token": valueToSave], forUserAccount: "bttvchat")
                }catch{
                    print(error)
                    do {
                        try Locksmith.deleteDataForUserAccount(userAccount: "bttvchat")
                    }catch{
                        print(error)
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
        
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "loadingOAuthToken")
        
        if self.hasOAuthToken()
        {
            if let completionHandler = self.oAuthTokenCompletionHandler
            {
                completionHandler(nil)
            }
        }
        else
        {
            if let completionHandler = self.oAuthTokenCompletionHandler
            {
                let error = NSError(domain: "OAuth error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not obtain an OAuth token", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
                
                completionHandler(error)
            }
        }
        self.oAuthTokenCompletionHandler = nil
    }
}
