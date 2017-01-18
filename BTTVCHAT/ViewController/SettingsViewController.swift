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
    }

    @IBAction func buttonPressed(_ sender: Any) {
        TwitchAPIManager.sharedInstance.oAuthToken = nil
        self.performSegue(withIdentifier: "logoutSegue", sender: self)
    }

}
