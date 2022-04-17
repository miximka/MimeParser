//
//  TestAdditions.swift
//  MimeParserTests
//
//  Created by miximka on 07.12.17.
//  Copyright © 2017 miximka. All rights reserved.
//

import Foundation

#if XCODE_PROJECT
extension Bundle {
    static var module: Bundle {
        return Bundle(for: TestAdditions.self)
    }
}
#endif

class TestAdditions {

    static func testResourceURL(withName name: String, extension ext: String) -> URL {
        return Bundle.module.url(forResource: name, withExtension: ext)!
    }

    static func testResourceData(withName name: String, extension ext: String) -> Data {
        let url = testResourceURL(withName: name, extension: ext)
        return try! Data(contentsOf: url)
    }

    static func testResourceString(withName name: String, extension ext: String) -> String {
        let data = testResourceData(withName: name, extension: ext)
        return String(data: data, encoding: .utf8)!
    }

}
