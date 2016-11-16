//
//  Stream.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/16/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//
class Stream{
    var viewers: Int?
    var status: String?
    var game: String?
    var name: String?
    
    init(viewers:Int, status:String, game:String, name:String){
        self.viewers = viewers
        self.status = status
        self.game = game
        self.name = name
    }
}
