//
//  Lexer.swift
//  MimeEmailParser
//
//  Created by Igor Rendulic on 4/2/20.
//
//  Copyright (c) 2020 Igor Rendulic. All rights reserved.
/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

// simple lexer kind of like this one: https://developer.apple.com/documentation/foundation/scanner but simpler and purpusful
public class Lexer {
    var input: String
    var position: String.Index
    
    init(input: String) {
        self.input = input
        self.position = input.startIndex
    }
    
    var start: Int {
        return input.distance(from: self.input.startIndex, to: self.input.startIndex)
    }
    
    var end: Int {
        return input.distance(from: self.input.startIndex, to: self.input.endIndex)
    }
    
    var newInput: String {
        get {
            return self.input
        }
        set {
            self.input = newValue
            self.position = newValue.startIndex
        }
    }
    
    func peek() -> Character? {
        guard position < input.endIndex else {
            return nil
        }
        return input[position]
    }
    
    func advance() {
        assert(position < input.endIndex, "cannot advance past end index")
        position = input.index(after: position)
    }
    
    func current() -> Character? {
        guard position < input.endIndex else {
            return nil
        }
        return input[position]
    }
    
    func next() -> Character? {
        if peek() != nil {
            position = input.index(after: position)
            return input[position]
        }
        return nil
    }
    
    func skipSpace() {
        let i = input.startIndex
        while i < input.endIndex {
            guard CharacterSet.whitespaces.contains(input[i].unicodeScalars.first!) else {
                return
            }
            input.remove(at: i)
        }
    }
    
    func size() -> Int {
        return input.count
    }
    
    func isEmpty() -> Bool {
        if input.isEmpty {
            return true
        }
        return false
    }
    
    func toString() -> String {
        return input
    }
}
