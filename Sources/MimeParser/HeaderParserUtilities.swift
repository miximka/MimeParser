//
//  HeaderParserUtilities.swift
//  MimeParser
//
//  Created by miximka on 11.12.17.
//  Copyright © 2017 miximka. All rights reserved.
//

import Foundation

struct HeaderFieldLexer {
    enum Special : String, SpecialProtocol {
        case leftParentheses = "("
        case rightParentheses = ")"
        case leftAngleBracket = "<"
        case rightAngleBracket = ">"
        case atSign = "@"
        case comma = ","
        case semicolon = ";"
        case colon = ":"
        case backslash = "\\"
        case quotationMark = "\""
        case slash = "/"
        case leftSquareBracket = "["
        case rightSquareBracket = "]"
        case questionMark = "?"
        case equalitySign = "="
        
        static let all: [Special] = {
            return [.leftParentheses,
                    .rightParentheses,
                    .leftAngleBracket,
                    .rightAngleBracket,
                    .atSign,
                    .comma,
                    .semicolon,
                    .colon,
                    .backslash,
                    .quotationMark,
                    .slash,
                    .leftSquareBracket,
                    .rightSquareBracket,
                    .questionMark,
                    .equalitySign
            ]
        }()
        
        static let rawValues: [String] = {
            return all.map { $0.rawValue }
        }()
    }
    
    enum Token : Equatable {
        case quotedString(String)
        case token(String)
        case special(Special)
        
        static func ==(lhs: Token, rhs: Token) -> Bool {
            switch (lhs, rhs) {
            case (.quotedString(let lhsS), .quotedString(let rhsS)): return lhsS == rhsS
            case (.token(let lhsS), .token(let rhsS)): return lhsS == rhsS
            case (.special(let lhsS), .special(let rhsS)): return lhsS == rhsS
            default: return false
            }
        }
    }
    
    private let invalidTokenChars: CharacterSet = {
        var set = CharacterSet(charactersIn: " ")
        set.insert(charactersIn: Range<Unicode.Scalar>(uncheckedBounds: (lower: Unicode.Scalar(0), upper: Unicode.Scalar(31))))
        set.insert(charactersIn: Special.all.reduce("", { return $0 + $1.rawValue }))
        return set
    }()
    
    private func nextToken(withScanner scanner: StringScanner<Special>) -> Token? {
        scanner.trimWhiteSpaces()
        
        do {
            let str = try scanner.scanTextEnclosed(left: .quotationMark, right: .quotationMark, excludedCharacters: invalidQTextChars)
            return .quotedString(str)
        } catch {
        }
        
        do {
            let str = try scanner.scanText(withExcludedCharacters: invalidTokenChars)
            return .token(str)
        } catch {
        }
        
        do {
            let special = try scanner.scanSpecial()
            return .special(special)
        } catch {
        }
        
        return nil
    }
    
    func scan(_ string: String) -> [Token] {
        let scanner = StringScanner<Special>(string)
        var tokens = [Token]()
        
        repeat {
            if let token = nextToken(withScanner: scanner) {
                tokens.append(token)
            } else {
                break
            }
        } while true
        
        return tokens
    }
}

// MARK: -

class HeaderFieldTokenProcessor {
    
    enum Error : Swift.Error {
        case noMoreTokens
        case invalidSpecial
        case invalidQuotedString
        case invalidToken
        case invalidAtom
    }
    
    let tokens: [HeaderFieldLexer.Token]
    
    init(tokens: [HeaderFieldLexer.Token]) {
        self.tokens = tokens
    }
    
    private var cursor: Int = 0
    
    var isAtEnd: Bool {
        return cursor == tokens.count
    }
    
    private func withNextToken<T>(_ probe: (HeaderFieldLexer.Token) throws -> T) throws -> T {
        guard cursor < tokens.count else { throw Error.noMoreTokens }
        let token = tokens[cursor]
        
        do {
            cursor += 1
            return try probe(token)
        } catch {
            cursor -= 1
            throw error
        }
    }
    
    func expectQuotedString() throws -> String {
        return try withNextToken { token -> String in
            guard case .quotedString(let value) = token else { throw Error.invalidQuotedString }
            return value
        }
    }
    
    func expectToken() throws -> String {
        return try withNextToken { token -> String in
            guard case .token(let value) = token else { throw Error.invalidToken }
            return value
        }
    }
    
    func expectSpecial(_ special: HeaderFieldLexer.Special) throws {
        try withNextToken { token in
            guard case .special(let value) = token, value == special else { throw Error.invalidSpecial }
        }
    }
}

// MARK: -

struct HeaderFieldParametersParser {
    
    enum Error : Swift.Error {
        case invalidParameterValue
        case trailingSemicolon
    }
    
    private struct Parameter {
        let name: String
        let value: String
    }
    
    private static func parseParameterName(with processor: HeaderFieldTokenProcessor) throws -> String {
        return try processor.expectToken()
    }
    
    private static func parseParameterValue(with processor: HeaderFieldTokenProcessor) throws -> String {
        do {
            return try processor.expectQuotedString()
        } catch {}
        
        do {
            return try processor.expectToken()
        } catch {}
        
        throw Error.invalidParameterValue
    }
    
    private static func parseParameter(with processor: HeaderFieldTokenProcessor) throws -> Parameter {
        try processor.expectSpecial(.semicolon)
        
        if processor.isAtEnd {
            throw Error.trailingSemicolon
        }
        
        let name = try parseParameterName(with: processor)
        try processor.expectSpecial(.equalitySign)
        let value = try parseParameterValue(with: processor)
        return Parameter(name: name, value: value)
    }
    
    static func parse(with processor: HeaderFieldTokenProcessor) throws -> [String : String] {
        var params: [String : String] = [:]
        while !processor.isAtEnd {
            do {
                let param = try parseParameter(with: processor)
                params[param.name] = param.value
            } catch let err as Error {
                if err != .trailingSemicolon {
                    throw err
                }
            }
        }
        return params
    }
}
