//
//  Mime+Initializers.swift
//  
//
//  Created by Ronald Mannak on 5/23/22.
//

import Foundation

public extension ContentType {
    
    init(type: String, subtype: String, parameters: [String: String], ignore: Bool = false) {
        self.type = type
        self.subtype = subtype
        self.parameters = parameters
    }
}

public extension ContentDisposition {
    
    init(type: String, parameters: [String: String], ignore: Bool = false) {
        self.type = type
        self.parameters = parameters
    }
}

public extension MimeHeader {
    
    init(encoding: ContentTransferEncoding?, type: ContentType?, disposition: ContentDisposition?, other: [RFC822HeaderField]) {
        self.contentTransferEncoding = encoding
        self.contentType = type
        self.contentDisposition = disposition
        self.other = other
    }
}

public extension Mime {
    
    init(header: MimeHeader, content: MimeContent, ignore: Bool = false) {
        self.header = header
        self.content = content
    }
}

public extension RFC822HeaderField {
    
    init(key: String, value: String) {
        self.name = key
        self.body = value
    }
}
