//
//  MimeHeaderParser.swift
//  MimeParser
//
//  Created by miximka on 08.12.17.
//  Copyright © 2017 miximka. All rights reserved.
//

import Foundation

class ContentTypeParser {
    
    private func parseContentTypeComponents(with processor: HeaderFieldTokenProcessor) throws -> (String, String) {
        let type = try processor.expectToken()
        try processor.expectSpecial(.slash)
        let subtype = try processor.expectToken()
        return (type, subtype)
    }
    
    func parse(_ string: String) throws -> ContentType {
        let lexer = HeaderFieldLexer()
        let tokens = lexer.scan(string)
        let processor = HeaderFieldTokenProcessor(tokens: tokens)
        let (type, subtype) = try parseContentTypeComponents(with: processor)
        let parameters = try HeaderFieldParametersParser.parse(with: processor)
        return ContentType(type: type, subtype: subtype, parameters: parameters)
    }
}

// MARK: -

class ContentTransferEncodingFieldParser {
    
    func parse(_ string: String) throws -> ContentTransferEncoding {
        let lexer = HeaderFieldLexer()
        let tokens = lexer.scan(string)
        let processor = HeaderFieldTokenProcessor(tokens: tokens)
        let encodingValue = try processor.expectToken()
        return ContentTransferEncoding(encodingValue)
    }
}

// MARK: -

class ContentDispositionFieldParser {
    
    func parse(_ string: String) throws -> ContentDisposition {
        let lexer = HeaderFieldLexer()
        let tokens = lexer.scan(string)
        let processor = HeaderFieldTokenProcessor(tokens: tokens)
        let value = try processor.expectToken()
        let parameters = try HeaderFieldParametersParser.parse(with: processor)
        return ContentDisposition(type: value, parameters: parameters)
    }
}

// MARK: -

struct HeaderParser {
    
    static func parse(_ string: String) throws -> MimeHeader {
        let unfolded = RFC822HeaderFieldsUnfolder().unfold(in: string)
        let fields = try RFC822HeaderFieldsPartitioner().fields(in: unfolded)
        
        var wrappedFields = [HeaderType]()
        for field in fields {
            try wrappedFields.append(HeaderType.wrap(field))            
        }
        return MimeHeader(fields: wrappedFields)
    }

}
