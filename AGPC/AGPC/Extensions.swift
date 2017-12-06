//
//  Extensions.swift
//  AGPC
//
//  Created by Andrey Gurev on 04.12.2017.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

extension Dictionary {
    mutating func update(other:Dictionary?) throws {
        if(other != nil) {
            for (key,value) in other! {
                if self.index(forKey: key) != nil {
                    throw ParseErrors.duplicateDeclaration((value as! Declaration).position, key as! String)
                }
                self.updateValue(value, forKey:key)
            }
        }
    }
}

extension String {
    var length: Int {
        return self.count
    }
    subscript (i: Int) -> String {
        return self[i..<i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    var asciiArray: [UInt32] {
        return unicodeScalars.filter{$0.isASCII}.map{$0.value}
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

extension Character {
    var asciiValue: Int {
        let value = String(self).unicodeScalars.filter{$0.isASCII}.first?.value
        return Int(value!)
    }
}
