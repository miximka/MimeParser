import XCTest
@testable import MimeParser

class EmailParsingTests: XCTestCase {

	static var allTests = [
		("testCanParseEmailWithApplicationAttachment",testCanParseEmailWithApplicationAttachment)
	]

	func testCanParseEmailWithApplicationAttachment() throws {
        // Given
		let parser = MimeParser()
		let message = TestAdditions.testResourceString(withName: "EmailWithApplicationAttachment", extension: "txt")

		// When
		let mime = try parser.parse(message)
		
        // Then
		XCTAssertEqual(mime.header.contentType?.type, "multipart")
		XCTAssertEqual(mime.header.contentType?.subtype, "mixed")

        if case .mixed(let mimes) = mime.content, let message = mimes.first, let attachment = mimes.last {
			XCTAssertEqual(mimes.count, 2)
            
            if case .alternative(let alternativeMessages) = message.content {
                XCTAssertEqual(alternativeMessages.count, 3)
                guard alternativeMessages.count == 3 else { return }
                
                XCTAssertEqual(alternativeMessages[0].header.contentType?.mimeType, .text)
                XCTAssertEqual(alternativeMessages[0].header.contentType?.subtype, "plain")
                XCTAssertEqual(alternativeMessages[0].header.contentTransferEncoding, .base64)

                XCTAssertEqual(alternativeMessages[1].header.contentType?.mimeType, .text)
                XCTAssertEqual(alternativeMessages[1].header.contentType?.subtype, "html")
                XCTAssertEqual(alternativeMessages[1].header.contentTransferEncoding, .quotedPrintable)

                XCTAssertEqual(alternativeMessages[2].header.contentType?.mimeType, .text)
                XCTAssertEqual(alternativeMessages[2].header.contentType?.subtype, "calendar")
                XCTAssertEqual(alternativeMessages[2].header.contentTransferEncoding, .sevenBit)
            }
            
            XCTAssertEqual(attachment.header.contentType?.mimeType, .application)
            XCTAssertEqual(attachment.header.contentType?.subtype, "ics")
            let attachmentContent = try attachment.decodedContentString() ?? ""
            XCTAssertTrue(attachmentContent.contains("VCALENDAR"))
            XCTAssertTrue(attachmentContent.contains("VEVENT"))
        } else {
            XCTFail("expected to find multipart/mixed mime")
        }
	}

}

