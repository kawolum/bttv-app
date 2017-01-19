//
//  NumberFormatController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/18/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class NumberFormatController: NSObject {
    static func commaFormattedNumber(number: Int) -> String{
        if number < 1000 {
            return number.description
        }
        
        var string = number.description
        
        var currentIndex = string.index(string.endIndex, offsetBy: -3, limitedBy: string.startIndex)
        
        while currentIndex != nil && currentIndex! != string.startIndex {
            string.insert(",", at: currentIndex!)
            currentIndex = string.index(currentIndex!, offsetBy: -3, limitedBy: string.startIndex)
        }
        
        return string
    }
}
