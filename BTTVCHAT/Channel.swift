//
//  Stream.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/16/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//
import UIKit

class Channel{
    var id: Int
    var viewers: Int
    var status: String
    var game: String
    var name: String
    var previewURL: String
    var previewImage: UIImage?
    
    init(id: Int, viewers: Int, status: String, game: String, name: String, previewURL: String){
        self.id = id
        self.viewers = viewers
        self.status = status
        self.game = game
        self.name = name
        self.previewURL = previewURL
    }
}
