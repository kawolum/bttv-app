//
//  TrieNode.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/13/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

class TrieNode<Element> {
    var dictionary = [Character : TrieNode]()
    var value: Element?
}
