//
//  UtilitiesTests.swift
//  MimeParserTests
//
//  Created by miximka on 08.12.17.
//  Copyright © 2017 miximka. All rights reserved.
//

import XCTest
@testable import MimeParser

class UtilitiesTests: XCTestCase {

    func testCanLeftTrimCharactersFromString() {
        // Given
        let str = " abc "
        
        // When
        let result = str.leftTrimmingCharacters(in: CharacterSet.whitespaces)
        
        // Then
        XCTAssertEqual(result, "abc ")
    }

    func testCanLeftTrimCharactersFromEmptyString() {
        // Given
        let str = ""
        
        // When
        let result = str.leftTrimmingCharacters(in: CharacterSet.whitespaces)
        
        // Then
        XCTAssertEqual(result, "")
    }

    func testCanDecodeQuotedPrintableString() throws {
        // Given
        let str = """
        Test1
        Test=C3=A4
        Test=3D
        Test
        Test=
        """
        
        // When
        let decoded = try str.decodedQuotedPrintable()
        let decodedString = String(data: decoded, encoding: .utf8)
        
        // Then
        let expected = """
        Test1
        Testä
        Test=
        Test
        Test
        """
        XCTAssertEqual(decodedString, expected)
    }

    func testCanDecodeLongQuotedPrintableString() throws {
        // Given
        let str = """
        TestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTes=
        tTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTe=
        st
        """
        
        // When
        let decoded = try str.decodedQuotedPrintable()
        let decodedString = String(data: decoded, encoding: .utf8)
        
        // Then
        let expected = "TestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTest"
        XCTAssertEqual(decodedString, expected)
    }

    func testCanFindNewLineRange() {
        // Given
        let data: Data = Data([0x61, 0x0A, 0x62]) // "a\nb"
        let str = String(data: data, encoding: .ascii)!
        
        // When
        let range = str.rangeOfRFC822NewLine(in: str.range)
        
        // Then
        let expectedRange = Range<String.Index>(uncheckedBounds: (str.index(str.startIndex, offsetBy: 1), str.index(str.startIndex, offsetBy: 2)))
        XCTAssertEqual(range, expectedRange)
        
        if let range = range {
            XCTAssertEqual(str[range], "\n")
            XCTAssertEqual(str.prefix(upTo: range.lowerBound), "a")
            XCTAssertEqual(str.suffix(from: range.upperBound), "b")
        } else {
            XCTFail("Invalid range")
        }
    }

    func testCanFindCRLNNewLineRange() {
        // Given
        let data: Data = Data([0x61, 0x0D, 0x0A, 0x62]) // "a\r\nb"
        let str = String(data: data, encoding: .ascii)!
        
        // When
        let range = str.rangeOfRFC822NewLine(in: str.range)
        
        // Then
        let expectedRange = Range<String.Index>(uncheckedBounds: (str.index(str.startIndex, offsetBy: 1), str.index(str.startIndex, offsetBy: 2)))
        XCTAssertEqual(range, expectedRange)

        if let range = range {
            XCTAssertEqual(str[range], "\r\n")
            XCTAssertEqual(str.prefix(upTo: range.lowerBound), "a")
            XCTAssertEqual(str.suffix(from: range.upperBound), "b")
        } else {
            XCTFail("Invalid range")
        }
    }

    func testCaseInsensitiveDictionary() {
        var dictionary: [String: Int] = ["One":1, "Two":2, "Three":3]

        XCTAssertEqual(1, dictionary[caseInsensitive: "ONE"])
        XCTAssertEqual(2, dictionary[caseInsensitive: "Two"])
        XCTAssertEqual(3, dictionary[caseInsensitive: "three"])

        dictionary[caseInsensitive: "one"] = 11
        dictionary[caseInsensitive: "TWO"] = 22
        dictionary[caseInsensitive: "ThReE"] = 33

        XCTAssertEqual(11, dictionary["One"])
        XCTAssertEqual(22, dictionary["Two"])
        XCTAssertEqual(33, dictionary["Three"])
    }
}
