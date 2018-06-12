//
//  ParsingMimeTests.swift
//  MimeParserTests
//
//  Created by miximka on 07.12.17.
//  Copyright © 2017 miximka. All rights reserved.
//

import XCTest
import MimeParser

class ParsingMimeTests: XCTestCase {

    func testCanParseSimpleMime() throws {
        // Given
        let parser = MimeParser()
        let message = """
            Content-Type: text/plain
            
            Test
            """
        
        // When
        let mime = try parser.parse(message)
        
        // Then
        XCTAssertEqual(mime.header.contentType?.type, "text")
        XCTAssertEqual(mime.header.contentType?.subtype, "plain")
        XCTAssertEqual(mime.header.contentType?.raw, "text/plain")
        XCTAssertEqual(mime.header.contentType?.mimeType, .text)
        XCTAssertNil(mime.header.contentTransferEncoding)
        XCTAssertEqual(mime.content, .body(MimeBody("Test")))
    }

    func testCanParseParameterWithTrailingSemicolon() throws {
        // Given
        let parser = MimeParser()
        let message = """
            Content-Type: text/plain;
            
            Test
            """
        
        // When
        let mime = try parser.parse(message)
        
        // Then
        XCTAssertEqual(mime.header.contentType?.raw, "text/plain")
        XCTAssertEqual(mime.content, .body(MimeBody("Test")))
    }
    
    func testCanParseSimpleMessage() throws {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "SimpleMessage", extension: "txt")
        
        // When
        let mime = try parser.parse(message)
        
        // Then
        XCTAssertEqual(mime.header.contentType?.type, "text")
        XCTAssertEqual(mime.header.contentType?.subtype, "plain")
        XCTAssertEqual(mime.header.contentType?.raw, "text/plain")
        XCTAssertEqual(mime.header.contentType?.mimeType, .text)
        XCTAssertEqual(mime.header.contentType?.parameters["charset"], "us-ascii")
        XCTAssertEqual(mime.header.other.count, 9)
        XCTAssertEqual(mime.header.contentTransferEncoding, .sevenBit)
        XCTAssertEqual(mime.content, .body(MimeBody("Test\n")))
    }

    func testCanParseMessageWithTextAttachment() throws {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "SimpleMessageWithTextAttachment", extension: "txt")
        
        // When
        let mime = try parser.parse(message)
        
        // Then
        XCTAssertEqual(mime.header.contentType?.type, "multipart")
        XCTAssertEqual(mime.header.contentType?.subtype, "mixed")
        XCTAssertEqual(mime.header.contentType?.raw, "multipart/mixed")
        XCTAssertEqual(mime.header.contentType?.mimeType, .multipart(subtype: .mixed, boundary: "Apple-Mail=_6019F987-AED7-497B-9323-66FED5C72DF3"))
        XCTAssertEqual(mime.header.other.count, 11)
        XCTAssertNil(mime.header.contentTransferEncoding)

        if case .mixed(let mimes) = mime.content {
            XCTAssertEqual(mimes.count, 2)
            
            let first = mimes.first
            XCTAssertEqual(first?.header.contentType?.type, "text")
            XCTAssertEqual(first?.header.contentType?.subtype, "plain")
            XCTAssertEqual(first?.header.contentType?.raw, "text/plain")
            XCTAssertEqual(first?.header.contentType?.mimeType, .text)
            XCTAssertEqual(first?.header.contentType?.parameters["charset"], "us-ascii")
            XCTAssertEqual(first?.header.other.count, 0)
            XCTAssertEqual(first?.header.contentTransferEncoding, .sevenBit)
            XCTAssertEqual(first?.content, .body(MimeBody("Fnord\n\n")))
            
            let last = mimes.last
            XCTAssertEqual(last?.header.contentType?.type, "text")
            XCTAssertEqual(last?.header.contentType?.subtype, "plain")
            XCTAssertEqual(last?.header.contentType?.raw, "text/plain")
            XCTAssertEqual(last?.header.contentType?.mimeType, .text)
            XCTAssertEqual(last?.header.contentType?.parameters["name"], "MyAttachment.txt")
            XCTAssertEqual(last?.header.contentDisposition?.type, "attachment")
            XCTAssertEqual(last?.header.contentDisposition?.parameters["filename"], "MyAttachment.txt")
            XCTAssertEqual(last?.header.contentTransferEncoding, .sevenBit)
            XCTAssertEqual(last?.content, .body(MimeBody("fnord\n")))
        } else {
            XCTFail("Unexpected mime content")
        }
    }

    func testCanParseMessageWithBinaryAttachment() throws {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "SimpleMessageWithBinaryAttachment", extension: "txt")
        
        // When
        let mime = try parser.parse(message)
        
        // Then
        if case .mixed(let mimes) = mime.content {
            XCTAssertEqual(mimes.count, 2)
            
            let first = mimes.first
            XCTAssertEqual(first?.header.contentType?.type, "text")
            XCTAssertEqual(first?.header.contentType?.subtype, "plain")
            XCTAssertEqual(first?.header.contentType?.raw, "text/plain")
            XCTAssertEqual(first?.header.contentType?.mimeType, .text)
            XCTAssertEqual(first?.header.contentType?.parameters["charset"], "us-ascii")
            XCTAssertEqual(first?.header.other.count, 0)
            XCTAssertEqual(first?.header.contentTransferEncoding, .sevenBit)
            XCTAssertEqual(first?.content, .body(MimeBody("Fnord\n")))
            
            let last = mimes.last
            XCTAssertEqual(last?.header.contentType?.raw, "application/octet-stream")
            XCTAssertEqual(last?.header.contentType?.mimeType, .application)
            XCTAssertEqual(last?.header.contentDisposition?.type, "attachment")
            XCTAssertEqual(last?.header.contentDisposition?.parameters["filename"], "binary.data")
            XCTAssertEqual(last?.header.contentTransferEncoding, .base64)
            XCTAssertEqual(last?.content, .body(MimeBody("//////////8=", encoding: .base64)))
            
            if let content = last?.content, case .body(let body) = content {
                let decoded = try body.decodedContentData()
                XCTAssertEqual(decoded, Data(bytes: [255, 255, 255, 255, 255, 255, 255, 255]))
            } else {
                XCTFail("Invalid attachment content")
            }
        } else {
            XCTFail("Invalid mime content")
        }
    }

    func testCanParseMessageWithBinaryAttachmentCRLNNewLines() throws {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "SimpleMessageWithBinaryAttachmentCRLN", extension: "txt")
        
        // When
        let mime = try parser.parse(message)
        
        // Then
        if case .mixed(let mimes) = mime.content {
            XCTAssertEqual(mimes.count, 2)
            
            let first = mimes.first
            XCTAssertEqual(first?.header.contentType?.type, "text")
            XCTAssertEqual(first?.header.contentType?.subtype, "plain")
            XCTAssertEqual(first?.header.contentType?.raw, "text/plain")
            XCTAssertEqual(first?.header.contentType?.mimeType, .text)
            XCTAssertEqual(first?.header.contentType?.parameters["charset"], "us-ascii")
            XCTAssertEqual(first?.header.other.count, 0)
            XCTAssertEqual(first?.header.contentTransferEncoding, .sevenBit)
            XCTAssertEqual(first?.content, .body(MimeBody("Fnord\r\n")))
            
            let last = mimes.last
            XCTAssertEqual(last?.header.contentType?.raw, "application/octet-stream")
            XCTAssertEqual(last?.header.contentType?.mimeType, .application)
            XCTAssertEqual(last?.header.contentDisposition?.type, "attachment")
            XCTAssertEqual(last?.header.contentDisposition?.parameters["filename"], "binary.data")
            XCTAssertEqual(last?.header.contentTransferEncoding, .base64)
            XCTAssertEqual(last?.content, .body(MimeBody("//////////8=", encoding: .base64)))
            
            if let content = last?.content, case .body(let body) = content {
                let decoded = try body.decodedContentData()
                XCTAssertEqual(decoded, Data(bytes: [255, 255, 255, 255, 255, 255, 255, 255]))
            } else {
                XCTFail("Invalid attachment content")
            }
        } else {
            XCTFail("Invalid mime content")
        }
    }

    func testCanParseQuotedPrintableMessage() throws {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "QuotedPrintableMessage", extension: "txt")
        
        // When
        let mime = try parser.parse(message)
        
        // Then
        XCTAssertEqual(mime.header.contentType?.type, "text")
        XCTAssertEqual(mime.header.contentType?.subtype, "plain")
        XCTAssertEqual(mime.header.contentType?.raw, "text/plain")
        XCTAssertEqual(mime.header.contentType?.mimeType, .text)
        XCTAssertEqual(mime.header.contentTransferEncoding, .quotedPrintable)
        
        let expectedDecodedContent = """
            Test1
            Testä
            Test=
            Test
            Test
            """
        
        if case .body(let body) = mime.content {
            let decoded = try body.decodedContentString(withIANACharsetName: mime.header.contentType?.charset)
            XCTAssertEqual(decoded, expectedDecodedContent)
        } else {
            XCTFail("Invalid attachment content")
        }
    }

    func testCanParseEnclosedMessageAsAttachment() throws {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "MessageWithEnclosedMessageAsAttachment", extension: "txt")
        
        // When
        let mime = try parser.parse(message)
        
        // Then
        XCTAssertEqual(mime.header.contentType?.raw, "multipart/mixed")
        XCTAssertEqual(mime.encapsulatedMimes.count, 2)
        
        let eml = mime.encapsulatedMime(withName: "SimpleMessage.eml")
        XCTAssertNotNil(eml)
        XCTAssertEqual(eml?.header.contentType?.raw, "message/rfc822")
        let decodedContent = try eml?.decodedContentString()
        XCTAssertEqual(decodedContent?.count, 602)
        
        let json = mime.encapsulatedMime(withName: "TestAttachment.json")
        XCTAssertNotNil(json)
        XCTAssertEqual(json?.header.contentType?.raw, "application/json")
        let decodedJson = try json?.decodedContentString()
        XCTAssertEqual(decodedJson?.count, 44)
    }
    
    func testCanParseBoundaryHavingSpecialCharacters() throws {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "SpecialCharsBoundary", extension: "txt")
        
        // When
        let mime = try parser.parse(message)
        
        // Then
        XCTAssertEqual(mime.header.contentType?.type, "multipart")
        XCTAssertEqual(mime.header.contentType?.subtype, "mixed")
        XCTAssertEqual(mime.header.contentType?.raw, "multipart/mixed")
        XCTAssertEqual(mime.header.contentType?.mimeType, .multipart(subtype: .mixed, boundary: "----sinikael-?=_1-15217146106530.0021966528779551187"))
        XCTAssertEqual(mime.header.other.count, 11)
        XCTAssertNil(mime.header.contentTransferEncoding)
        
        if case .mixed(let mimes) = mime.content {
            XCTAssertEqual(mimes.count, 2)
        } else {
            XCTFail("Unexpected mime content")
        }
    }
    
    func testCanParseEmailWithApplicationAttachment() throws {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "EmailWithApplicationAttachment", extension: "txt")
        
        // When
        let mime = try parser.parse(message)
        // Then
        XCTAssertEqual(mime.header.contentType?.type, "multipart")
        XCTAssertEqual(mime.header.contentType?.subtype, "mixed")
        
        if case .mixed(let mimes) = mime.content {
            //dump(mimes)
            XCTAssertEqual(mimes.count, 2)
            
            for part in mimes {
                
                let mimeType = part.header.contentType?.mimeType
                let mimeSubType = part.header.contentType?.subtype
                
                if mimeType == .application {
                    XCTAssertTrue(mimeSubType == "ics")
                    let content = try part.decodedContentString()
                    XCTAssertNotNil(content)
                    XCTAssertTrue(content!.contains("VCALENDAR"))
                    XCTAssertTrue(content!.contains("VEVENT"))
                    dump(content)
                    return
                }
            }
            
            XCTAssert(false)

        }
        
    }

}
