//
//  ChatUITableView.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/5/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class ChatUITableView: UITableView {
    
    var atBottom = true
    var start = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if start && atBottom {
            stickToBottom()
        }
    }
    
    func startSticktoBottom() {
        start = true
    }
    
    func stickToBottom(){
        let sec = self.numberOfSections - 1
        let row = self.numberOfRows(inSection: sec) - 1
        DispatchQueue.main.async {
            super.scrollToRow(at: IndexPath(row: row, section: sec), at: UITableViewScrollPosition.bottom, animated: false)
        }
    }
}
