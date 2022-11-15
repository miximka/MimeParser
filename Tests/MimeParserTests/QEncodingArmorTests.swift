//
//  QTextParsingTests.swift
//  
//
//  Created by Ronald Mannak on 11/9/22.
//

import XCTest
@testable import MimeParser

final class QEncodingParsingTests: XCTestCase {
        
    // Example signature before encoding
    let signature = """

        -----BEGIN PGP SIGNATURE-----
        Version: Pretty Good Crypto / 0.1
        Charset: UTF-8
        Comment: https://www.moonfish.app

        wksEAQEIAAAAAF1oKoCekByATESuUDbdfBLmKNg2KQheeuwplxvmaoE2+ocsXaa6
        fBrA8mZBdGqc6JpvI+jZZjuawfbEpLVnuIDy+xvGMwQAAAAAFgkrBgEEAdpHDwEB
        B0BcxPkLWV4bdUNBMXmo2zZcp/f2fxFSFHEn6DzbL7PSTg==
        =bbWu
        -----END PGP SIGNATURE-----
        """
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMailHeader() throws {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "QTextHeaderMessage", extension: "eml")
        
        let mime = try parser.parse(message)
        // Replace /t with /n
        let string = mime.header.value(for: "X-moonfish")!.replacingOccurrences(of: "/t", with: "/n")

        let decoded = try string.rfc2047decode()
        XCTAssertEqual(signature, decoded)
    }
    
    func testSwiftScanner() throws {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "QTextHeaderMessage", extension: "eml")
        
        let mime = try parser.parse(message)
        let string = mime.header.value(for: "X-moonfish")!
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = nil
        let qStart = "=?" //CharacterSet(charactersIn: "=?")
        let qEnd = "?=" //CharacterSet(charactersIn: "?=")
        let wordDecoder = QEncoder()
        
        var decodedString = ""
        var word: String = ""
        
        // Find start of Qtext
        _ = scanner.scanUpToString(qStart)
        
        while !scanner.isAtEnd {
            word = word + (scanner.scanString(qStart) ?? "") // Scan q start
            word = word + (scanner.scanUpToString("?") ?? "") // scan up to first ?
            word = word + (scanner.scanString("?") ?? "") // scan first ?
            word = word + (scanner.scanUpToString("?") ?? "") // scan up to second ?
            word = word + (scanner.scanString("?") ?? "") // scan second ?
            word = word + (scanner.scanUpToString(qEnd) ?? "") // scan up to end
            word = word + (scanner.scanString(qEnd) ?? "") // scan end
            
            print("found word: \(word)")
            decodedString = try decodedString + wordDecoder.decodeRFC2047Word(word: word)
            word = ""
            
            decodedString = decodedString + (scanner.scanUpToString(qStart) ?? "")
        }
        print(decodedString)
        
        let rfDecoded = try string.rfc2047decode()
        XCTAssertEqual(rfDecoded, signature)
    }
    
    func testStringDecoder() throws {
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "QTextHeaderMessage", extension: "eml")
        
        let mime = try parser.parse(message)
        let string = mime.header.value(for: "X-moonfish")!
        
        let decoded = try string.rfc2047decode()
        XCTAssertEqual(decoded, signature)
    }
    
    func testStringDecoder2() throws {
        let singleLineDecoded = "=?UTF-8?Q?=0A-----BEGIN?= PGP =?UTF-8?Q?SIGNATURE-----=0AVersion=3A?= Pretty Good Crypto / =?UTF-8?Q?0=2E1=0ACharset=3A_UTF-8=0AComment=3A?= =?UTF-8?Q?_https=3A=2F=2Fwww=2Emoonfish=2Eapp=0A=0AwksEAQEIAAAAA?= =?us-ascii?Q?F1oKoCekByATESuUDbdfBLmKNg2KQheeuwplxvm?= =?UTF-8?Q?aoE2+ocsXaa6=0AfBrA8mZBdGqc6JpvI+jZZjuawf?= =?UTF-8?Q?bEpLVnuIDy+xvGMwQAAAAAFgkrBgEEAdpHDwEB=0A?= =?us-ascii?Q?B0BcxPkLWV4bdUNBMXmo2zZcp=2Ff2fxFSFHEn6Dz?= =?UTF-8?Q?bL7PSTg=3D=3D=0A=3DbbWu=0A-----END?= PGP SIGNATURE-----"
        let parser = MimeParser()
        let message = TestAdditions.testResourceString(withName: "QTextHeaderMessage", extension: "eml")
        
        let mime = try parser.parse(message)
        let string = mime.header.value(for: "X-moonfish")!
        
        XCTAssertEqual(string, singleLineDecoded)
        
        let decoded = try string.rfc2047decode()
        XCTAssertEqual(decoded, signature)
    }
    
    func testSignatureRoundtrip() throws {
        let encoded = signature.rfc2047encode()
        let decoded = try encoded.rfc2047decode()
        XCTAssertEqual(decoded, signature)
        print(encoded)
        print(signature)
    }
    
    func testEspecial() throws {
        let especial = "()<>@,;:\"/[]?.="
        let encoded = especial.rfc2047encode()
        let decoded = try encoded.rfc2047decode()
        XCTAssertEqual(especial, decoded)
    }
    
    func testExtendedAsciiChar() throws {
        let extendedAscii = "™" //©äü"
        let encoded = extendedAscii.rfc2047encode()
        let decoded = try encoded.rfc2047decode()
        XCTAssertEqual(extendedAscii, decoded)
    }
    
    func testExtendedAscii() throws {
        let extendedAscii = "žœäü"
        let encoded = extendedAscii.rfc2047encode()
        let decoded = try encoded.rfc2047decode()
        XCTAssertEqual(extendedAscii, decoded)
    }
    
    func testUnicode() throws {
        let extendedAscii = "🐶"
        let encoded = extendedAscii.rfc2047encode()
        let decoded = try encoded.rfc2047decode()
        XCTAssertEqual(extendedAscii, decoded)
    }    
}
