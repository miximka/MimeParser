//
//  MimeHeader.swift
//  
//
//  Created by Ronald Mannak on 6/14/22.
//

import Foundation

// MARK: - MimeHeader

public struct MimeHeader {
    
    public var contentTransferEncoding: ContentTransferEncoding? {
        return fields.compactMap({ header -> ContentTransferEncoding? in
            switch header {
            case .contentTransferEncoding(let encoding):
                return encoding
            default:
                return nil
            }
        }).first
    }
    
    public var contentType: ContentType? {
        return fields.compactMap({ header -> ContentType? in
            switch header {
            case .contentType(let contentType):
                return contentType
            default:
                return nil
            }
        }).first
    }
    
    public var contentDisposition: ContentDisposition? {
        return fields.compactMap({ header -> ContentDisposition? in
            switch header {
            case .contentDisposition(let contentDisposition):
                return contentDisposition
            default:
                return nil
            }
        }).first
    }
    
    @available(*, deprecated, message: "Use fields property instead")
    public var other: [RFC822HeaderField] {
        return fields.compactMap({ header -> RFC822HeaderField? in
            switch header {
            case .other(let field):
                return field
            default:
                return nil
            }
        })
    }
    
    public let fields: [HeaderType]
        
    public init(fields: [HeaderType]) {
        self.fields = fields
    }
}

extension MimeHeader {
    
    /// Exports headers to a RFC822 formatted string
    /// - Parameter mailKit: Uses Apple MailKit conform line endings if true (\n instead of \r\n)
    /// - Returns: RFC822 formatted string
    func rfc822String(mailKit: Bool = true) -> String {
        let lf = mailKit ? "\n" : "\r\n"
        let t = mailKit ? "\t" : "    "
        var string = ""
                
        for field in fields {
            switch field {
            case .contentTransferEncoding(let encoding):
                string = string + "Content-Transfer-Encoding: \(encoding.description)\(lf)"
            case .contentType(let type):
                string = string + "Content-Type: \(type.raw)"
                for (key, value) in type.parameters {
                    assert(key.lowercased() != "content-type")
                    string = string + ";\(lf)\(t)\(key)=\"\(value)\""
                }
                string = string + lf
            case .contentDisposition(let disposition):
                string = string + "Content-Disposition: \(disposition.type)"
                for (key, value) in disposition.parameters {
                    assert(key.lowercased() != "Content-Disposition")
                    string = string + ";\(lf)\(t)\(key)=\(value)"
                }
                string = string + lf
            case .other(let header):
                string = string + "\(header.name): \(header.body)\(lf)"
            }
        }
        return string
    }
}

extension MimeHeader : Equatable {

    public static func ==(lhs: MimeHeader, rhs: MimeHeader) -> Bool {
        return lhs.fields == rhs.fields
    }
}

// MARK: - HeaderType

public enum HeaderType: Equatable {
    case contentTransferEncoding(ContentTransferEncoding)
    case contentType(ContentType)
    case contentDisposition(ContentDisposition)
//    case to([EmailField])
//    case cc([EmailField])
//    case bcc([EmailField])
    case other(RFC822HeaderField)
}

// MARK: - RFC822HeaderField
public struct RFC822HeaderField : Equatable {
    public let name: String
    public let body: String
    
    public static func ==(lhs: RFC822HeaderField, rhs: RFC822HeaderField) -> Bool {
        return lhs.name == rhs.name && lhs.body == rhs.body
    }
}

extension RFC822HeaderField {
    
    public init(key: String, value: String) {
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
    
    public init(type: String, subtype: String, parameters: [String: String], ignore: Bool = false) {
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

extension ContentDisposition {
    
    public init(type: String, parameters: [String: String], ignore: Bool = false) {
        self.type = type
        self.parameters = parameters
    }
}

// MARK: - EmailField
/*
public struct EmailField {
    public let name: String?
    public let address: String
 
    public init(name: String?, address: String) {
        self.name = name
        self.address = address
    }
    
    // move to HeaderParser
    static func parse(string: String) -> [EmailField] {
        let rawAddresses = string.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
//        if < then look until > everything in bwtn is email 
    }
}
*/

