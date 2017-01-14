//
//  AppDelegate.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/3/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        TwitchAPIManager.sharedInstance.processOAuthResponse(url: url)
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        if !TwitchAPIManager.sharedInstance.hasOAuthToken(){
            showLoginScreen(animated: false)
        }
        
        return true
    }
    
    func showLoginScreen(animated: Bool){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        self.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
    }
}

