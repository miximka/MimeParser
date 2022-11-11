//
//  MimeHeader.swift
//  
//
//  Created by Ronald Mannak on 5/18/22.
//

import Foundation

public extension MimeHeader {
    
    var contentDescription: String? {
        return value(for: "Content-Description")
    }
    
    /// Returns body of RFC822 header for key.
    /// If the body is RFC 2047 (Q Text) encoded, it will decode automatically
    /// - Parameter key: header key (case insensitive)
    /// - Returns: body string or nil if key isn't found
    func value(for key: String) -> String? {
        guard let body = self.header(for: key)?.body else {
            return nil
        }
//        if let rfc2047encoded = try? body.rfc2047decode() {
//            return rfc2047encoded
//        }
        return body
    }
    
    /// Returns RFC822 header for key.
    /// - Parameter key: header key (case insensitive)
    /// - Returns: header or nil if key isn't found
    func header(for key: String) -> RFC822HeaderField? {
        return self.other.filter { $0.name.lowercased() == key.lowercased() }.first
//        return self.fields.filter { $0.name.lowercased() == key.lowercased() }.first
    }
    
    var sender: String? {
        return header(for: "from")?.body
    }
    
    var to: String? {
        return header(for: "to")?.body
    }
    
}
