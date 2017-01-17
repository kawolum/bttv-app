//
//  DisplayNameColorCache.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/3/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class DisplayNameColorCache{
    static let sharedCache : NSCache<NSString, UIColor> = {
        let cache = NSCache<NSString, UIColor>()
        cache.name = "MyDisplayNameColorCache"
        cache.countLimit = 500
        cache.totalCostLimit = 5*1024*1024
        return cache
    }()
    
    static func getColor(key: String) -> UIColor?{
        return sharedCache.object(forKey: NSString(string: key))
    }
    
    static func setColor(key: String, value: UIColor){
        sharedCache.setObject(value, forKey: NSString(string: key))
    }
}
