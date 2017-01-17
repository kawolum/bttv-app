//
//  ImageCache.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/2/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class ImageCache {
    static let sharedCache : NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.name = "MyImageCache"
        cache.countLimit = 50
        cache.totalCostLimit = 8*1024*1024
        return cache
    }()
    
    static func getImage(key: String) -> UIImage?{
        return sharedCache.object(forKey: NSString(string: key))
    }
    
    static func setImage(key: String, value: UIImage){
        sharedCache.setObject(value, forKey: NSString(string: key))
    }
}
