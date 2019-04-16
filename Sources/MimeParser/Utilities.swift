//
//  Utilities.swift
//  MimeParser
//
//  Created by miximka on 06.12.17.
//  Copyright © 2017 miximka. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    
    mutating func remove(_ element: Element) {
        if let index = firstIndex(of: element) {
            remove(at: index)
        }
    }
}

extension String {
    
    var range: Range<String.Index> {
        return Range<String.Index>(uncheckedBounds: (lower: startIndex, upper: endIndex))
    }
    
    var nsRange: NSRange {
        return NSRange(range, in: self)
    }
    
    func rangeOfRFC822NewLine(in searchRange: Range<String.Index>) -> Range<String.Index>? {
        let regex = try! NSRegularExpression(pattern: "\r?\n", options: [])
        let matchResults = regex.firstMatch(in: self, options: [], range: NSRange(searchRange, in: self))
        let range = matchResults.flatMap { Range<String.Index>($0.range, in: self) }
        return range
    }
}

extension String {
    
    func leftTrimmFirstCharacter(in set: CharacterSet) -> String {
        guard startIndex != endIndex else { return self }
        
        let range = Range<String.Index>(uncheckedBounds: (lower: startIndex, upper: index(after: startIndex)))
        if rangeOfCharacter(from: set, options: [], range: range) != nil {
            return String(suffix(from: range.upperBound))
        }
        
        return self
    }
    
    func leftTrimmingCharacters(in set: CharacterSet) -> String {
        var idx = startIndex
        repeat {
            if idx == endIndex {
                break
            }
            
            let range = Range<String.Index>(uncheckedBounds: (lower: idx, upper: index(after: idx)))
            if rangeOfCharacter(from: set, options: [], range: range) != nil {
                idx = index(after: idx)
            } else {
                break
            }
        } while true
        
        if idx == startIndex {
            return self
        }
        
        return String(suffix(from: idx))
    }
}

extension String {
    
    enum QuotedPrintableDecoderError : Error {
        case invalidQuotedPrintableString
    }
    
    enum QPDecodingState {
        case consumedEqualSign
        case consumedFirstDigit(UTF8.CodeUnit)
        case decoded(UInt8)
    }
    
    func decodedQuotedPrintable() throws -> Data {
        let charDecoder: (QPDecodingState?, UTF8.CodeUnit) throws -> QPDecodingState? = { previousState, codeUnit in
            if let state = previousState {
                switch state {
                case .consumedEqualSign:
                    if codeUnit == 0xD {
                        return .consumedEqualSign
                    } else if codeUnit == 0xA {
                        return nil
                    }
                    return .consumedFirstDigit(codeUnit)
                case .consumedFirstDigit(let firstDigit):
                    let first = Character(UnicodeScalar(firstDigit))
                    let second = Character(UnicodeScalar(codeUnit))
                    let str = "\(first)\(second)"
                    if let value = Int(str, radix: 16), value < 256 {
                        return .decoded(UInt8(value))
                    } else {
                        throw QuotedPrintableDecoderError.invalidQuotedPrintableString
                    }
                case .decoded(_):
                    throw QuotedPrintableDecoderError.invalidQuotedPrintableString
                }
            }
            
            if codeUnit == 0x3d {
                return .consumedEqualSign
            }
            
            return .decoded(codeUnit)
        }
        
        var decodedData = Data()
        var prevState: QPDecodingState?
        
        for each in utf8 {
            if let state = try charDecoder(prevState, each) {
                switch state {
                case .consumedEqualSign:
                    fallthrough
                case .consumedFirstDigit:
                    prevState = state
                case .decoded(let codeUnit):
                    decodedData.append(codeUnit)
                    prevState = nil
                }
            } else {
                prevState = nil
            }
        }
        
        return decodedData
    }
    
}

extension Dictionary where Key == String {
    subscript(caseInsensitive key: Key) -> Value? {
        get {
            if let k = keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                return self[k]
            }
            return nil
        }
        set {
            if let k = keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                self[k] = newValue
            } else {
                self[key] = newValue
            }
        }
    }
}
