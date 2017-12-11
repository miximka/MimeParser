//
//  RFC822ParsingUtilitiesTests.swift
//  MimeParserTests
//
//  Created by miximka on 06.12.17.
//  Copyright © 2017 miximka. All rights reserved.
//

import XCTest
@testable import MimeParser

class RFC822ParsingUtilitiesTests: XCTestCase {

    // MARK: - Unfolding Header Fields
    
    func testCanUnfoldFieldHavingOneSpace() {
        // Given
        let unfolder = RFC822HeaderFieldsUnfolder()
        let folded = "a\r\n b\r\n"
        
        // When
        let unfolded = unfolder.unfold(in: folded)
        
        // Then
        XCTAssertEqual(unfolded, "a b\r\n")
    }

    func testCanUnfoldFieldHavingMultipleSpaces() {
        // Given
        let unfolder = RFC822HeaderFieldsUnfolder()
        let folded = "a\r\n     b\r\n"
        
        // When
        let unfolded = unfolder.unfold(in: folded)
        
        // Then
        XCTAssertEqual(unfolded, "a b\r\n")
    }

    func testCanUnfoldFieldHavingTabs() {
        // Given
        let unfolder = RFC822HeaderFieldsUnfolder()
        let folded = "a\r\n\t\tb\r\n"
        
        // When
        let unfolded = unfolder.unfold(in: folded)
        
        // Then
        XCTAssertEqual(unfolded, "a b\r\n")
    }

    func testCanUnfoldMultipleFields() {
        // Given
        let unfolder = RFC822HeaderFieldsUnfolder()
        let folded = "a\r\n b\r\nc\r\n\td"
        
        // When
        let unfolded = unfolder.unfold(in: folded)
        
        // Then
        XCTAssertEqual(unfolded, "a b\r\nc d")
    }
    
    // MARK: - Partitioning Header Fiels
    
    func testCanPartitionField() throws {
        // Given
        let partitioner = RFC822HeaderFieldsPartitioner()
        let str = """
            a: b
            c:  d
            """
        
        // When
        let fields = try partitioner.fields(in: str)
        
        // Then
        let expected = [RFC822HeaderField(name: "a", body: "b"), RFC822HeaderField(name: "c", body: "d")]
        XCTAssertEqual(fields, expected)
    }
    
    // MARK: - Scanning Tokens

    func testScanOutOfBounds() throws {
        // Given
        let str = ""
        let scanner = StringScanner<RFC822Special>(str)
        
        // When
        var err: Error?
        do {
            let _ = try scanner.scanSpecial()
        } catch {
            err = error
        }
        
        // Then
        XCTAssertNotNil(err)
    }
    
    func testCanScanSpecial() throws {
        // Given
        let str = ";:"
        let scanner = StringScanner<RFC822Special>(str)
        
        // When
        let special1 = try scanner.scanSpecial()
        let special2 = try scanner.scanSpecial()

        // Then
        XCTAssertEqual(special1, .semicolon)
        XCTAssertEqual(special2, .colon)
    }

    func testCanScanQuotedString() throws {
        // Given
        let str = "\"abc\""
        let scanner = StringScanner<RFC822Special>(str)
        
        // When
        let text = try scanner.scanTextEnclosed(left: .quotationMark, right: .quotationMark, excludedCharacters: CharacterSet(charactersIn: "\""))
        
        // Then
        XCTAssertEqual(text, "abc")
    }

    func testCanScanAtom() throws {
        // Given
        let str = "abc"
        let scanner = StringScanner<RFC822Special>(str)
        
        // When
        let text = try scanner.scanAtom()
        
        // Then
        XCTAssertEqual(text, "abc")
    }

    func testAtomScanStopsOnSpace() throws {
        // Given
        let str = "abc def"
        let scanner = StringScanner<RFC822Special>(str)
        
        // When
        let text = try scanner.scanAtom()
        
        // Then
        XCTAssertEqual(text, "abc")
    }
}
