//
//  StringExtension.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 11/8/16.
//  Copyright © 2016 Ka Lum. All rights reserved.
//

extension String {
    func index(of string: String, options: String.CompareOptions = .literal) -> String.Index? {
        return range(of: string, options: options, range: nil, locale: nil)?.lowerBound
    }

    public func indexOfCharacter(char: Character) -> Int? {
        if let idx = characters.index(of: char) {
            return characters.distance(from: startIndex, to: idx)
        }
        return nil
    }
}
