import XCTest
@testable import MimeParser

class EmailParsingTests: XCTestCase {
    let parser = MimeParser()
    let message = TestAdditions.testResourceString(withName: "EmailWithApplicationAttachment", extension: "txt")
    private var mime: Mime!
    
    override func setUpWithError() throws {
        let tempMime = try parser.parse(message)
        XCTAssertNotNil(tempMime)
        mime = tempMime
    }

	static var allTests = [
		("testCanParseEmailWithApplicationAttachment",testCanParseEmailWithApplicationAttachment)
	]

    /// Tests the second child part of the message (application/ics).
	func testCanParseEmailWithApplicationAttachment() throws {
		XCTAssertEqual(mime.header.contentType?.type, "multipart")
		XCTAssertEqual(mime.header.contentType?.subtype, "mixed")

        guard case .mixed(let mimes) = mime.content else {
            XCTAssert(false)
            return
        }
        
        XCTAssertEqual(mimes.count, 2)
            
        let part = mimes[1]

        let mimeType = part.header.contentType?.mimeType
        let mimeSubType = part.header.contentType?.subtype
        
        XCTAssertEqual(mimeType, .application)
        XCTAssertTrue(mimeSubType == "ics")
        
        let content = try part.decodedContentString()
        XCTAssertNotNil(content)
        XCTAssertTrue(content!.contains("VCALENDAR"))
        XCTAssertTrue(content!.contains("VEVENT"))
	}
    
    /// Test the first child part of the message (multipart/alternative).
    func testCanParseEmailWithMultipartAlternative() throws {
        XCTAssertEqual(mime.header.contentType?.type, "multipart")
        XCTAssertEqual(mime.header.contentType?.subtype, "mixed")

        guard case .mixed(let mimes) = mime.content else {
            XCTAssert(false)
            return
        }
        
        XCTAssertEqual(mimes.count, 2)
            
        let part = mimes[0]
        
        let childMimeType = part.header.contentType?.mimeType
        let childMimeSubType = part.header.contentType?.mimeType
        
        XCTAssertNotNil(childMimeType)
        XCTAssertNotNil(childMimeSubType)
        
        XCTAssertEqual(childMimeType, .multipart(subtype: .alternative, boundary: "000000000000cb0123056e6493f5"))
        
        guard case .alternative(let alts) = part.content else {
            XCTAssert(false)
            return
        }
        
        /// number of alternative parts
        XCTAssertEqual(alts.count, 3)
        
        
    }

}

