//
//  MimeParser.swift
//  MimeParser
//
//  Created by miximka on 06.12.17.
//  Copyright © 2017 miximka. All rights reserved.
//

import Foundation

struct MimePartsSplitter {
    
    struct Parts {
        let header: Range<String.Index>
        let body: Range<String.Index>
    }
    
    static func findParts(in string: String) -> Parts? {
        var emptyLineRange: Range<String.Index>?
        var searchRange = string.range
        
        repeat {
            guard let nextEmptyLineRange = string.rangeOfRFC822NewLine(in: searchRange) else {
                break
            }
            
            if searchRange.lowerBound == nextEmptyLineRange.lowerBound || nextEmptyLineRange.upperBound == string.endIndex {
                emptyLineRange = nextEmptyLineRange
            } else {
                searchRange = Range<String.Index>(uncheckedBounds: (nextEmptyLineRange.upperBound, string.endIndex))
            }
            
        } while emptyLineRange == nil
        
        guard let range = emptyLineRange else { return nil }
        let headerRange = Range(uncheckedBounds: (string.startIndex, range.lowerBound))
        let bodyRange = Range(uncheckedBounds: (range.upperBound, string.endIndex))
        return Parts(header: headerRange, body: bodyRange)
    }
}

// MARK: - MimeParser

public struct MimeParser {
    
    enum Error : Swift.Error {
        case invalidMessageStructure
    }
    
    public init() {
    }
    
    private func parseCompositeContent(in string: String, range: Range<String.Index>, boundary: String) throws -> [Mime] {
        let escapedBoundary = boundary.replacingOccurrences(of: "?", with: "\\?")
        let regex = try! NSRegularExpression(pattern: "\r?\n--\(escapedBoundary)-?-?\r?\n", options: [])
        let matchResults = regex.matches(in: string, options: [], range: string.nsRange)
        
        var mimes = [Mime]()
        var prevRange: Range<String.Index>?
        
        for each in matchResults {
            guard let range = Range<String.Index>(each.range, in: string) else {
                throw Error.invalidMessageStructure
            }
            
            if let prevRange = prevRange {
                let partRange = Range<String.Index>(uncheckedBounds: (lower: prevRange.upperBound, upper: range.lowerBound))
                let part = String(string[partRange])
                let mime = try parse(part)
                mimes.append(mime)
            }
            
            prevRange = range
        }
        
        return mimes
    }
    
    private func parseDiscreteContent(in string: String, range: Range<String.Index>, encoding: ContentTransferEncoding?) -> MimeContent {
        let body = MimeBody(String(string[range]), encoding: encoding)
        return .body(body)
    }
    
    private func parseContent(in string: String, range: Range<String.Index>, contentType: ContentType?, encoding: ContentTransferEncoding?) throws -> MimeContent {
        guard let contentType = contentType else {
            return parseDiscreteContent(in: string, range: range, encoding: encoding)
        }
        
        let content: MimeContent
        
        switch contentType.mimeType {
        case .multipart(let subtype, let boundary):
            let mimes = try parseCompositeContent(in: string, range: range, boundary: boundary)
            switch subtype {
            case .mixed:
                content = .mixed(mimes)
            case .alternative:
                content = .alternative(mimes)
            case .other(_):
                content = .mixed(mimes)
            }
        case .text: fallthrough
        case .image: fallthrough
        case .audio: fallthrough
        case .video: fallthrough
        case .application: fallthrough
        case .message: fallthrough
        case .other(_):
            content = parseDiscreteContent(in: string, range: range, encoding: encoding)
        }
        
        return content
    }
    
    public func parse(_ string: String) throws -> Mime {
        guard let parts = MimePartsSplitter.findParts(in: string) else {
            throw Error.invalidMessageStructure
        }
        
        let header = try HeaderParser.parse(String(string[parts.header]))
        
        let content = try parseContent(in: string,
                                       range: parts.body,
                                       contentType: header.contentType,
                                       encoding: header.contentTransferEncoding)
        
        return Mime(header: header, content: content)
    }
    
}
