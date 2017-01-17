//
//  Emote.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/13/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

class MessageEmote: Emote{
    var startIndex: Int
    var length: Int
    
    init(id: String, text: String, better: Bool, type: String, startIndex: Int, length: Int){
        self.startIndex = startIndex
        self.length = length
        super.init(id: id, text: text, better: better, type: type)
    }
}
