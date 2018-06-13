//
//  TestAdditions.swift
//  MimeParserTests
//
//  Created by miximka on 07.12.17.
//  Copyright © 2017 miximka. All rights reserved.
//

import Foundation

class TestAdditions {

    static func testResourceURL(withName name: String, extension ext: String) -> URL {
	    let file = Resource(name: name, type: ext)
	    return URL(fileURLWithPath: file.path)
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

class Resource {
    static var resourcePath = "./Tests/Supporting Files"

    let name: String
    let type: String

    init(name: String, type: String) {
        self.name = name
        self.type = type
    }

    var path: String {
	#if os(macOS) || os(iOS) || os(tvOS)
	return Bundle(for: Swift.type(of: self)).path(forResource: name, ofType: type)
	#else
	let filename: String = type.isEmpty ? name : "\(name).\(type)"
	return "\(Resource.resourcePath)/\(filename)"
	#endif
    }
}
