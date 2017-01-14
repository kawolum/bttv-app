//
//  bttvEmote.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/2/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

class Emote{
    var id: String
    var text: String
    var better: Bool
    var type: String
    
    init(id: String, text: String, better: Bool, type: String){
        self.id = id
        self.text = text
        self.better = better
        self.type = type
    }
}
