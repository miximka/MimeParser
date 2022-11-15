//
//  Mime.swift
//  MimeParser
//
//  Created by miximka on 08.12.17.
//  Copyright © 2017 miximka. All rights reserved.
//

import Foundation

// MARK: - MultipartSubtype
public enum MultipartSubtype : Equatable {
    case mixed
    case alternative
//    case encrypted
    case other(String)
    
    init(_ string: String) {
        switch string.lowercased() {	// case-insensitive: https://datatracker.ietf.org/doc/html/rfc2045#section-5.1
        case "mixed": self = .mixed
        case "alternative": self = .alternative
//        case "encrypted": self = .encrypted
        default: self = .other(string)
        }
    }
    
    public static func ==(lhs: MultipartSubtype, rhs: MultipartSubtype) -> Bool {
        switch (lhs, rhs) {
        case (.mixed, .mixed): return true
        case (.alternative, .alternative): return true
//        case (.encrypted, .encrypted): return true
        case (.other(let lhsValue), .other(let rhsValue)): return lhsValue == rhsValue
        default: return false
        }
    }
}

// MARK: - MimeType
public enum MimeType : Equatable {
    case text
    case image
    case audio
    case video
    case application
    case message
    case multipart(subtype: MultipartSubtype, boundary: String)
    case other(String)
    
    public static func ==(lhs: MimeType, rhs: MimeType) -> Bool {
        switch (lhs, rhs) {
        case (.text, .text): return true
        case (.image, .image): return true
        case (.audio, .audio): return true
        case (.video, .video): return true
        case (.application, .application): return true
        case (.message, .message): return true
        case (.multipart(let lhsSubtype, let lhsBoundary), .multipart(let rhsSubtype, let rhsBoundary)): return lhsSubtype == rhsSubtype && lhsBoundary == rhsBoundary
        case (.other(let lhsValue), .other(let rhsValue)): return lhsValue == rhsValue
        default: return false
        }
    }
}

//extension MimeType: CustomStringConvertible {
//   
//    public var description: String {
//        switch(self) {
//        case text
//        case image
//        case audio
//        case video
//        case application
//        case message
//        case multipart(subtype: MultipartSubtype, boundary: String)
//        case other(String)
//        }
//    }
//}

// MARK: - MimeBody
public struct MimeBody : Equatable {
    
    enum Error : Swift.Error {
        case invalidCharset
    }
    
    public let raw: String
    public let encoding: ContentTransferEncoding
    
    public init(_ raw: String, encoding: ContentTransferEncoding? = nil) {
        self.raw = raw
        self.encoding = encoding ?? .sevenBit
    }
    
    public static func ==(lhs: MimeBody, rhs: MimeBody) -> Bool {
        return lhs.raw == rhs.raw && lhs.encoding == rhs.encoding
    }
    
    public func decodedContentData() throws -> Data {
        return try MimeContentDecoder.decode(raw, encoding: encoding)
    }

    #if os(macOS) || os(iOS) || os(tvOS)
    #else
    private let ianaTable: [String.Encoding: String] = [.ascii: "us-ascii", .nextstep: "x-nextstep",
                                                        .japaneseEUC: "euc-jp", .utf8: "utf-8", .isoLatin1: "iso-8859-1",
                                                        .symbol: "x-mac-symbol", .shiftJIS: "cp932", .isoLatin2: "iso-8859-2",
                                                        .windowsCP1251: "windows-1251", .windowsCP1252: "windows-1252",
                                                        .windowsCP1253: "windows-1253", .windowsCP1254: "windows-1254",
                                                        .windowsCP1250: "windows-1250", .iso2022JP: "iso-2022-jp", .macOSRoman: "macintosh",
                                                        .utf16: "utf-16", .utf16BigEndian: "utf-16be", .utf16LittleEndian: "utf-16le",
                                                        .utf32: "utf-32", .utf32BigEndian: "utf-32be", .utf32LittleEndian: "utf-32le"]
    #endif
    
    public func decodedContentString(withIANACharsetName charset: String?) throws -> String {
        let data = try decodedContentData()
        
        #if os(macOS) || os(iOS) || os(tvOS)
            let stringEncoding: String.Encoding? = charset.flatMap { charset in
                let cfEncoding = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
                let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
                return String.Encoding(rawValue: nsEncoding)
            }
       #else
            // this as workaround for CFStringConvertIANACharSetNameToEncoding
            // since it is not exposed in SwiftFoundation until it got fixed
            let stringEncoding: String.Encoding? = charset.flatMap { charset in
		    let charset = charset.lowercased()
		    return ianaTable.filter({ return $0.value == charset }).first?.key ?? .utf8
            }
        #endif
        
        guard let decoded = String(data: data, encoding: stringEncoding ?? .utf8) else {
            throw Error.invalidCharset
        }
        
        return decoded
    }
    
}

// MARK: - MimeContent
public enum MimeContent {
    case body(MimeBody)
    case mixed([Mime])
    case alternative([Mime])
//    case encrypted([Mime])
}

extension MimeContent : Equatable {
    public static func ==(lhs: MimeContent, rhs: MimeContent) -> Bool {
        switch (lhs, rhs) {
        case (.body(let _lhsBody), .body(let _rhsBody)): return _lhsBody == _rhsBody
        case (.mixed(let lhsValue), .mixed(let rhsValue)): return lhsValue == rhsValue
        case (.alternative(let lhsValue), .alternative(let rhsValue)): return lhsValue == rhsValue
//        case (.encrypted(let lhsValue), .encrypted(let rhsValue)): return lhsValue == rhsValue
        default: return false
        }
    }
}

// MARK: - Mime
public struct Mime :Equatable {
    public let header: MimeHeader
    public let content: MimeContent

    public static func ==(lhs: Mime, rhs: Mime) -> Bool {
        return lhs.header == rhs.header && lhs.content == rhs.content
    }
    
    public func decodedContentData() throws -> Data? {
        switch content {
        case .body(let body):
            return try body.decodedContentData()
        case .mixed:
            return nil
        case .alternative:
            return nil
//        case .encrypted(let)) for encrypted, can we add the "encrypted by..." footnote here?
        }
    }
    
    public func decodedContentString() throws -> String? {
        switch content {
        case .body(let body):
            let charset = header.contentType?.charset
            return try body.decodedContentString(withIANACharsetName: charset)
        case .mixed:
            return nil
        case .alternative:
            return nil
//        case .encrypted(let body):
        }
    }
}

extension Mime {
            
    public init(header: MimeHeader, content: MimeContent, ignore: Bool = false) {
        self.header = header
        self.content = content
    }
    
    public var encapsulatedMimes: [Mime] {
        switch content {
        case .body: return []
        case .mixed(let mimes): return mimes
        case .alternative(let mimes): return mimes
        }
    }
    
    public func encapsulatedMime(withName name: String) -> Mime? {
        return encapsulatedMimes.first { $0.header.contentType?.name == name }
    }

    public func attachment(withFilename filename: String) -> Mime? {
        return encapsulatedMimes.first { $0.header.contentDisposition?.filename == filename }
    }
        
    /// Exports Mime to a string conform RFC-822 of Mime
    /// - Parameter mailKit: Uses Apple MailKit conform line endings if true (\n instead of \r\n)
    /// - Returns: RFC-822 formatted string
    public func rfc822String(mailKit: Bool = true) throws -> String {
        return try rfc822Str(mailKit: mailKit)
    }
    
    /// Exports Mime to a string conform RFC-822
    /// - Parameters:
    ///   - boundary: Optional boundary string. Pass nil for top level Mime.
    ///   - mailKit: Uses Apple MailKit conform line endings if true (\n instead of \r\n)
    /// - Returns: RFC-822 formatted string
    private func rfc822Str(boundary: String? = nil, mailKit: Bool = true) throws -> String {
        let lf = mailKit ? "\n" : "\r\n"
        var string = ""
        
        switch self.content {
        case .body(let body):
            string = string + (boundary != nil ? "\(lf)--\(boundary!)\(lf)" : "") // last lf should be \n only for MailKit
            string = string + self.header.rfc822String(mailKit: mailKit) + "\n"
            string = string + body.raw
        case .mixed(let parts), .alternative(let parts):
            if let _ = boundaryString(), let boundary = boundary {
                // new nested part
                string = string + "\(lf)--\(boundary)\n"
            }
            string = string + self.header.rfc822String(mailKit: mailKit) + "\n"
            for part in parts {
                string = string + (try part.rfc822Str(boundary: boundaryString()))
            }
            string = string + (boundaryString() != nil ? "\(lf)--\(boundaryString()!)--\(lf)" : "") // last lf should be \n only for MailKit
        }
        return string
    }
    
    public func boundaryString() -> String? {
        return header.contentType?.parameters["boundary"]
    }
}
