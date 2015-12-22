//
//  String+Utilities.swift
//  Vind
//
//  Created by Jens Utbult on 2015-12-04.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import Foundation

extension Character {
    
    public var utf16: UInt16 {
        get {
            let s = String(self).utf16
            return s[s.startIndex]
        }
    }
    
    internal func intValue() -> Int? {
        let zero = 0x30
        let nine = 0x39
        let value = Int(self.utf16)
        switch (value) {
        case zero...nine:
            return value - zero
        default:
            return nil
        }
    }
}


extension String {
    
    func stripNonNumberCharacters() -> String? {
        var start = self.startIndex
        while start != self.endIndex && self[start].intValue() == nil {
            start = start.successor()
        }
        if start == self.endIndex {
            return nil
        }
        var end = start
        while end != self.endIndex && (self[end].intValue() != nil || self[end] == ".") {
            end = end.successor()
        }
        return self.substringWithRange(start..<end)
    }
}