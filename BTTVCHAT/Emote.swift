//
//  Emote.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/13/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

class Emote{
    var emoteID: String
    var emoteText: String
    var startIndex: Int
    var length: Int
    var better = false
    
    init(emoteID : String, emoteText : String, startIndex : Int, length : Int, better : Bool){
        self.emoteID = emoteID
        self.emoteText = emoteText
        self.startIndex = startIndex
        self.length = length
        self.better = better
    }
}
