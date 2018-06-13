import XCTest
@testable import MimeParser

class EmailParsingTests: XCTestCase {

	static var allTests = [
		("testCanParseEmailWithApplicationAttachment",testCanParseEmailWithApplicationAttachment)
	]

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
					return
				}
			}

			XCTAssert(false)
		}
	}

}

