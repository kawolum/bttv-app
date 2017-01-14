//
//  SettingsViewController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/7/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        print(TwitchAPIManager.sharedInstance.oAuthToken)
    }

}
