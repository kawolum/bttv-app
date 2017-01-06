//
//  ChatUITableView.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/5/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class ChatUITableView: UITableView {
    
    var reloadDataCompletionBlock: (() -> Void)?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.reloadDataCompletionBlock?()
    }
    
    func reloadDataWithCompletion(completion: @escaping () -> Void) {
        reloadDataCompletionBlock = completion
        super.reloadData()
    }
    
    func scrollToBottom(){
        self.scrollToRow(at: IndexPath(row: self.numberOfRows(inSection: self.numberOfSections - 1) - 1, section: self.numberOfSections - 1), at: UITableViewScrollPosition.bottom, animated: false)
    }
}
