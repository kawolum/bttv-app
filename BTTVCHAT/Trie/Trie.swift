//
//  Trie.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/13/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

struct Trie<Element> {
    let root = TrieNode<Element>();

    func insert(key: String, value: Element){
        var current = root
        
        for character in key.characters{
            if current.dictionary[character] == nil{
                current.dictionary[character] = TrieNode<Element>()
            }
            current = current.dictionary[character]!
        }
        
        current.value = value
    }
    
    func search(key: String) -> Element?{
        var current = root
        
        for character in key.characters{
            if current.dictionary[character] == nil{
                return nil
            }
            current = current.dictionary[character]!
        }
        
        return current.value
    }
}
