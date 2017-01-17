//
//  InitialViewController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/7/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if TwitchAPIManager.sharedInstance.hasOAuthToken(){
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "loginSegue", sender: self)
            }
        }
    }
    @IBAction func buttonPressed(_ sender: Any) {
        TwitchAPIManager.sharedInstance.startOAuth2Login(){ error in
            if error == nil{
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "loginSegue", sender: self)
                }
            }else{
                print(error!)
            }
        }
    }
}
