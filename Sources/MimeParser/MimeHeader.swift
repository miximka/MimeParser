//
//  File.swift
//  
//
//  Created by Ronald Mannak on 6/14/22.
//

import Foundation

// MARK: - MimeHeader

public struct MimeHeader {
    public let contentTransferEncoding: ContentTransferEncoding?
    public let contentType: ContentType?
    public let contentDisposition: ContentDisposition?
    public let other: [RFC822HeaderField]
}

extension MimeHeader {
    
    init(encoding: ContentTransferEncoding?, type: ContentType?, disposition: ContentDisposition?, other: [RFC822HeaderField]) {
        self.contentTransferEncoding = encoding
        self.contentType = type
        self.contentDisposition = disposition
        self.other = other
    }
    
    /// Exports headers to a RFC822 formatted string
    /// - Returns: RFC822 formatted string
    func rfc822String() -> String {
        var string = ""
        
        if let encoding = self.contentTransferEncoding {
            string = string + "Content-Transfer-Encoding: \(encoding.description)\r\n"
        }
        
        if let type = self.contentType {
            string = string + "Content-type: \(type.raw)"
            for (key, value) in type.parameters {
                assert(key.lowercased() != "content-type")
                string = string + ";\r\n    \(key)=\"\(value)\""
            }
            string = string + "\r\n"
        }
        
        if let disposition = self.contentDisposition {
            string = string + "Content-Disposition: \(disposition.type)"
            for (key, value) in disposition.parameters {
                assert(key.lowercased() != "Content-Disposition")
                string = string + ";\r\n    \(key)=\(value)"
            }
            string = string + "\r\n"
        }
        
        for header in other {
            string = string + "\(header.name): \(header.body)\r\n"
        }
        
        return string
    }
}

extension MimeHeader : Equatable {

    public static func ==(lhs: MimeHeader, rhs: MimeHeader) -> Bool {
        return lhs.contentTransferEncoding == rhs.contentTransferEncoding &&
            lhs.contentType == rhs.contentType &&
            lhs.other == rhs.other
    }
}

// MARK: - RFC822HeaderField
public struct RFC822HeaderField : Equatable {
    public let name: String
    public let body: String
    
    public static func ==(lhs: RFC822HeaderField, rhs: RFC822HeaderField) -> Bool {
        return lhs.name == rhs.name && lhs.body == rhs.body
    }
}

public extension RFC822HeaderField {
    
    init(key: String, value: String) {
        self.name = key
        self.body = value
    }
}

// MARK: - ContentTransferEncoding
public enum ContentTransferEncoding : Equatable {
    case sevenBit
    case eightBit
    case binary
    case quotedPrintable
    case base64
    case other(String)
    
    init(_ string: String) {
        switch string.lowercased() {    // case-insensitive: https://datatracker.ietf.org/doc/html/rfc2045#section-6.1
        case "7bit": self = .sevenBit
        case "8bit": self = .eightBit
        case "binary": self = .binary
        case "quoted-printable": self = .quotedPrintable
        case "base64": self = .base64
        default: self = .other(string)
        }
    }
    
    public static func ==(lhs: ContentTransferEncoding, rhs: ContentTransferEncoding) -> Bool {
        switch (lhs, rhs) {
        case (.sevenBit, .sevenBit): return true
        case (.eightBit, .eightBit): return true
        case (.binary, .binary): return true
        case (.quotedPrintable, .quotedPrintable): return true
        case (.base64, .base64): return true
        case (.other(let lhsValue), .other(let rhsValue)): return lhsValue == rhsValue
        default: return false
        }
    }
}

extension ContentTransferEncoding: CustomStringConvertible {
   
    public var description: String {
        switch(self) {
        case .sevenBit:
            return "7bit"
        case .eightBit:
            return "8bit"
        case .binary:
            return "binary"
        case .quotedPrintable:
            return "quoted-printable"
        case .base64:
            return "base64"
        case .other(let string):
            return string
        }
    }
}

// MARK: - ContentType
public struct ContentType : Equatable {
    public let type: String
    public let subtype: String
    public let parameters: [String : String]
    
    public var raw: String {
        return "\(type)/\(subtype)"
    }
    
    public var charset: String? {
        return parameters["charset"]
    }

    public var name: String? {
        return parameters["name"]
    }
    
    public static func ==(lhs: ContentType, rhs: ContentType) -> Bool {
        return lhs.type == rhs.type && lhs.subtype == rhs.subtype && lhs.parameters == rhs.parameters
    }
}

extension ContentType {
    public var mimeType: MimeType {
        switch type.lowercased() {    // case-insensitive: https://datatracker.ietf.org/doc/html/rfc2045#section-5.1
        case "text": return .text
        case "image": return .image
        case "audio": return .audio
        case "video": return .video
        case "application": return .application
        case "message": return .message
        case "multipart":
            if let boundary = parameters["boundary"] {
                let subtype = MultipartSubtype(self.subtype)
                return .multipart(subtype: subtype, boundary: boundary)
            } else {
                return .other(type)
            }
        default: return .other(type)
        }
    }
    
    init(type: String, subtype: String, parameters: [String: String], ignore: Bool = false) {
        self.type = type
        self.subtype = subtype
        self.parameters = parameters
    }
}

// MARK: - ContentDisposition
public struct ContentDisposition : Equatable {
    public let type: String
    public let parameters: [String : String]
    
    public var filename: String? {
        return parameters["filename"]
    }
    
    public static func ==(lhs: ContentDisposition, rhs: ContentDisposition) -> Bool {
        return lhs.type == rhs.type && lhs.parameters == rhs.parameters
    }
}

public extension ContentDisposition {
    
    init(type: String, parameters: [String: String], ignore: Bool = false) {
        self.type = type
        self.parameters = parameters
    }
}



