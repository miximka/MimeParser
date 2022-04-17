import XCTest
@testable import MimeParser

class EmailParsingTests: XCTestCase {
    let parser = MimeParser()
    let message = TestAdditions.testResourceString(withName: "EmailWithApplicationAttachment", extension: "txt")
    private var mimes: [Mime]!
    
    override func setUpWithError() throws {
        let mime = try parser.parse(message)
        XCTAssertNotNil(mime)
        
        XCTAssertEqual(mime.header.contentType?.type, "multipart")
        XCTAssertEqual(mime.header.contentType?.subtype, "mixed")
        
        guard case .mixed(let mimes) = mime.content else {
            XCTAssert(false)
            return
        }
        
        XCTAssertEqual(mimes.count, 2)
        
        self.mimes = mimes
    }

	static var allTests = [
		("testCanParseEmailWithApplicationAttachment",testCanParseEmailWithApplicationAttachment),
        ("testCanParseEmailWithMultipartAlternative",testCanParseEmailWithMultipartAlternative)
	]

    /// Tests the second child part of the message (application/ics).
	func testCanParseEmailWithApplicationAttachment() throws {
        let part = mimes[1]
        
        /// Testing Content-Type
        XCTAssertEqual(part.header.contentType?.mimeType, .application)
        XCTAssertEqual(part.header.contentType?.subtype, "ics")
        
        XCTAssertEqual(part.header.contentType?.parameters["name"], "invite.ics")
        
        /// Testing Content-Disposition
        XCTAssertEqual(part.header.contentDisposition?.type, "attachment")
        XCTAssertEqual(part.header.contentDisposition?.filename, "invite.ics")
        
        /// Testing Content-Transfer-Encoding
        XCTAssertEqual(part.header.contentTransferEncoding, .base64)
        
        /// Testing MIME part body content
        let content = try part.decodedContentString()
        XCTAssertNotNil(content)
        XCTAssertTrue(content!.contains("VCALENDAR"))
        XCTAssertTrue(content!.contains("VEVENT"))
	}
    
    /// Test the first child part of the message (multipart/alternative).
    func testCanParseEmailWithMultipartAlternative() throws {
        let part = mimes[0]
        
        /// Testing multipart/alternative content type
        XCTAssertEqual(part.header.contentType?.mimeType,
                       .multipart(subtype: .alternative, boundary: "000000000000cb0123056e6493f5"))
        XCTAssertEqual(part.header.contentType?.subtype, "alternative")
        
        /// Unwrapping alternative Mime array
        guard case .alternative(let alts) = part.content else {
            XCTAssert(false)
            return
        }
        
        /// number of expected alternative parts
        XCTAssertEqual(alts.count, 3)
        
        /// Adding the if statements because the above assertion failure will not stop function execution.
        if alts.count >= 1 {
            /// Testing the first alternative part (type text/plain)
            XCTAssertEqual(alts[0].header.contentType?.mimeType, .text)
            XCTAssertEqual(alts[0].header.contentType?.subtype, "plain")
            
            XCTAssertEqual(alts[0].header.contentType?.parameters["charset"], "UTF-8")
            XCTAssertEqual(alts[0].header.contentType?.parameters["format"], "flowed")
            XCTAssertEqual(alts[0].header.contentType?.parameters["delsp"], "yes")
            
            XCTAssertEqual(alts[0].header.contentTransferEncoding, .base64)
        }
        
        if alts.count >= 2 {
            /// Testing the second alternative part (type text/html)
            XCTAssertEqual(alts[1].header.contentType?.mimeType, .text)
            XCTAssertEqual(alts[1].header.contentType?.subtype, "html")
            
            XCTAssertEqual(alts[1].header.contentType?.parameters["charset"], "UTF-8")
            
            XCTAssertEqual(alts[1].header.contentTransferEncoding, .quotedPrintable)
        }
        
        if alts.count >= 3 {
            /// Testing the third alternative part (type text/calendar)
            XCTAssertEqual(alts[2].header.contentType?.mimeType, .text)
            XCTAssertEqual(alts[2].header.contentType?.subtype, "calendar")
            
            XCTAssertEqual(alts[2].header.contentType?.parameters["charset"], "UTF-8")
            XCTAssertEqual(alts[2].header.contentType?.parameters["method"], "REQUEST")
        }
    }

}

