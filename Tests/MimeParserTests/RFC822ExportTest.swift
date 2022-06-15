//
//  RFC822ExportTest.swift
//  
//
//  Created by Ronald Mannak on 6/14/22.
//

import XCTest
@testable import MimeParser

class RFC822ExportTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSimpleMessage() throws {
        // When
        let (message, rfc822) = try fileToRFC822(resource: "SimpleMessage")
        // Then
        XCTAssertEqual(message, rfc822)
    }
    
    func testSimpleMessageWithBinaryAttachment() throws {
        // When
        let (message, rfc822) = try fileToRFC822(resource: "SimpleMessageWithBinaryAttachment")
        // Then
        XCTAssertEqual(message, rfc822)
    }
    
    func testSimpleMessageWithBinaryAttachmentCRLN() throws {
        // When
        let (message, rfc822) = try fileToRFC822(resource: "SimpleMessageWithBinaryAttachmentCRLN")
        // Then
        XCTAssertEqual(message, rfc822)
    }
    
    func testSimpleMessageWithTextAttachment() throws {
        // When
        let (message, rfc822) = try fileToRFC822(resource: "SimpleMessageWithTextAttachment")
        // Then
        XCTAssertEqual(message, rfc822)
    }
    
    func testSpecialCharsBoundary() throws {
        // When
        let (message, rfc822) = try fileToRFC822(resource: "SpecialCharsBoundary")
        // Then
        XCTAssertEqual(message, rfc822)
    }
    
    func testEmailWithApplicationAttachment() throws {
        // When
        let (message, rfc822) = try fileToRFC822(resource: "EmailWithApplicationAttachment")
        // Then
        XCTAssertEqual(message, rfc822)
    }
    
    func testEmailWithEmptyCc() throws {
        // When
        let (message, rfc822) = try fileToRFC822(resource: "EmptyCc")
        // Then
        XCTAssertEqual(message, rfc822)
    }
    
    func testMeetingRequestWithZeroLengthPart() throws {
        // When
        let (message, rfc822) = try fileToRFC822(resource: "MeetingRequestWithZeroLengthPart")
        // Then
        XCTAssertEqual(message, rfc822)
    }

    func testMessageWithEnclosedMessageAsAttachment() throws {
        // When
        let (message, rfc822) = try fileToRFC822(resource: "MessageWithEnclosedMessageAsAttachment")
        // Then
        XCTAssertEqual(message, rfc822)
    }
    
    func testQuotedPrintableMessage() throws {
        // When
        let (message, rfc822) = try fileToRFC822(resource: "QuotedPrintableMessage")
        // Then
        XCTAssertEqual(message, rfc822)
    }

    func fileToRFC822(resource: String) throws -> (String, String) {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: resource, extension: "txt")

        let mime = try parser.parse(message)
        let rfc822 = try mime.rfc822String()
        return (message, rfc822)
    }
}
