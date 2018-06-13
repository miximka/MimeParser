import XCTest
@testable import MimeParserTests 

XCTMain([
	testCase(MimeParsingTests.allTests),
	testCase(EmailParsingTests.allTests)
])
