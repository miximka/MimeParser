//
//  String+extension.swift
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

public func customPrint(items:Any..., separator:String = " ", terminator:String =  "\n") {
    #if DEBUG
    debugPrint(items, separator: separator, terminator: terminator)
    #endif
}

public extension StringProtocol {
    subscript(_ offset: Int)                     -> Element     { self[index(startIndex, offsetBy: offset)] }
    subscript(_ range: Range<Int>)               -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }
    subscript(_ range: ClosedRange<Int>)         -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }
    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence { prefix(range.upperBound.advanced(by: 1)) }
    subscript(_ range: PartialRangeUpTo<Int>)    -> SubSequence { prefix(range.upperBound) }
    subscript(_ range: PartialRangeFrom<Int>)    -> SubSequence { suffix(Swift.max(0, count-range.lowerBound)) }
    func indexDistance(of string: Self) -> Int? {
        guard let index = range(of: string)?.lowerBound else { return nil }
        return distance(from: startIndex, to: index)
    }
}


public extension String {
    func countInstances(of charToFind:Character) -> Int {
       return self.filter { $0 == charToFind }.count
    }
}


//
//  Character+extension.swift
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

extension Character {
    /// Will return the UInt32 unicode value for first scalar in Character
    /// Returns: UInt32 value of unicode character
    func unicodeScalarCodePoint() -> UInt32 {
        return unicodeScalars.first!.value
    }
}

public extension String {

    /*
     This version adds extra spaces
    func rfc2047decode() throws -> String {
        let separator = CharacterSet(charactersIn: " \t")
        var words = self.components(separatedBy: separator)
        // trimmingCharacters(in: .whitespacesAndNewlines)
        let wordDecoder = RFC2047Decoder()
        for (idx, word) in words.enumerated() {
            do {
                let decoded = try wordDecoder.decodeRFC2047Word(word: word)
                // word was decoded, replace in splitted array
                words[idx] = decoded
            } catch {
                continue // word  not encoded, skip
            }
        }
        return words.joined(separator: " ")
    }
    */
    
    func rfc2047decode() throws -> String {
        let scanner = Scanner(string: self)
        scanner.charactersToBeSkipped = nil
        let qStart = "=?"
        let qEnd = "?="
        let wordDecoder = RFC2047Decoder()
        
        var decodedString = ""
        
        // Find start of Qtext
        _ = scanner.scanUpToString(qStart)
        while !scanner.isAtEnd {
            var word: String = ""
            word = word + (scanner.scanString(qStart) ?? "") // Scan q start
            word = word + (scanner.scanUpToString("?") ?? "") // scan up to first ?
            word = word + (scanner.scanString("?") ?? "") // scan first ?
            word = word + (scanner.scanUpToString("?") ?? "") // scan up to second ?
            word = word + (scanner.scanString("?") ?? "") // scan second ?
            word = word + (scanner.scanUpToString(qEnd) ?? "") // scan up to end
            word = word + (scanner.scanString(qEnd) ?? "") // scan end
            decodedString = try decodedString + wordDecoder.decodeRFC2047Word(word: word)
            
            // There could be an unencoded plain text at the end of the line
            if let postfix = scanner.scanUpToString(qStart) {
                guard postfix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { continue }
                decodedString = decodedString + postfix
            }
        }
        return decodedString
    }
    
    
    /// For now just return ascii
    /// - Returns: RFC 2047 encoded string
    func rfc2047encode() -> String {
        var lines = self.components(separatedBy: .newlines)
        for (idx, line) in lines.enumerated() {
            let line = "=?us-ascii?Q?" + line + "?="
            lines[idx] = line
        }
        return lines.joined(separator: "\n")
    }
}
