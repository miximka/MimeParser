//
//  MimeContentDecoder.swift
//  MimeParser
//
//  Created by miximka on 10.12.17.
//  Copyright © 2017 miximka. All rights reserved.
//

import Foundation

struct MimeContentDecoder {
    
    enum Error : Swift.Error {
        case decodingFailed
        case unsupportedEncoding
    }

    static func decodeBase64(_ string: String) throws -> Data {
        let concatenated = string.replacingOccurrences(of: "\r?\n", with: "", options: .regularExpression, range: string.range)
        guard let data = Data(base64Encoded: concatenated) else {
            throw Error.decodingFailed
        }
        return data
    }

    static func decode(_ raw: String, encoding: ContentTransferEncoding) throws -> Data {
        switch encoding {
        case .sevenBit: fallthrough
        case .eightBit: fallthrough
        case .binary:
            guard let decoded = raw.data(using: .ascii) else { throw Error.decodingFailed }
            return decoded
        case .quotedPrintable:
            return try raw.decodedQuotedPrintable()
        case .base64:
            return try decodeBase64(raw)
        case .other(_):
            throw Error.unsupportedEncoding
        }
    }
    
}
