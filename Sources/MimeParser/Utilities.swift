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
    
    public var quotedPrintableDecoded: String {
        guard let decodedData = try? self.decodedQuotedPrintable(), let decoded = String(data: decodedData, encoding: .utf8) else { return self }
        return decoded
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

extension String {
    
    public func encode(_ encoding: ContentTransferEncoding) throws -> String {
        switch encoding {
        case .sevenBit: fallthrough
        case .eightBit: fallthrough
        case .binary:
            return self
        case .quotedPrintable:
            var gen = self.utf8.makeIterator()
            var charCount = 0
            
            var result = ""
            result.reserveCapacity(self.count)
            
            while let c = gen.next() {
                switch c {
                case 32...60, 62...126:
                    charCount += 1
                    result.unicodeScalars.append(UnicodeScalar(c))
                case 13:
                    continue
                case 10:
                    if result.hasSuffix(" ") || result.hasSuffix("\t") {
                        result.append("=\n")
                        charCount = 0
                    } else {
                        result.append("\n")
                        charCount = 0
                    }
                default:
                    if charCount > 72 {
                        result.append("=\n")
                        charCount = 0
                    }
                    result.append("=" + c.hexString().uppercased())
                    charCount+=3
                }
                
                if charCount == 75 {
                    charCount = 0
                    result.append("=\n")
                }
            }
            
            return result
        case .base64:
            guard let data = Data(base64Encoded: self),
            let encoded = String(data: data, encoding: .utf8) else { throw MimeContentDecoder.Error.unsupportedEncoding }
            return encoded
        case .other(_):
            throw MimeContentDecoder.Error.unsupportedEncoding
        }
    }
}

extension Dictionary where Key == String {
    public subscript(caseInsensitive key: Key) -> Value? {
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

// Source: https://github.com/dunkelstern/QuotedPrintable/blob/master/QuotedPrintable/quotedprintable.swift
extension UInt8 {
    func hexString(padded: Bool = true) -> String {
        let dict:[Character] = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
        var result = ""

        let c1 = Int(self >> 4)
        let c2 = Int(self & 0xf)

        if c1 == 0 && padded {
            result.append(dict[c1])
        } else if c1 > 0 {
            result.append(dict[c1])
        }
        result.append(dict[c2])

        if (result.count == 0) {
            return "0"
        }
        return result
    }
}
