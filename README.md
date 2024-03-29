[![Build Status](https://app.travis-ci.com/miximka/MimeParser.svg?branch=master)](https://app.travis-ci.com/miximka/MimeParser)
## About
**MimeParser** is a simple MIME (Multipurpose Internet Mail Extensions) parsing library written in Swift (to learn more about mimes refer to [RFC 822](https://tools.ietf.org/html/rfc822), [RFC 2045](https://tools.ietf.org/html/rfc2045), [RFC 2046](https://tools.ietf.org/html/rfc2046))

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate **MimeParser** into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
project '<Your Project Name>.xcodeproj'
platform :osx, '10.12'

target 'Test' do
  use_frameworks!
  pod 'MimeParser', '~> 0.1'
end
```

Then, run the following command:

```bash
$ pod install
```

## Usage

Import **MimeParser** before using it:

```swift
import MimeParser
```

Create parser object:

```swift
let parser = MimeParser()
```

Let this be a simplest mime to be parsed:

```swift
let str = """
	Content-Type: text/plain
	
	Test
	"""
```

You are ready to parse the mime:

```swift
let mime = try parser.parse(str)
```

Returned `mime` object is a root of the mime tree and provides access to its `header` fields and `content`:

```swift
public enum MimeContent {
    case body(MimeBody)
    case mixed([Mime])
    case alternative([Mime])
}

public struct MimeHeader {
    public let contentTransferEncoding: ContentTransferEncoding?
    public let contentType: ContentType?
    public let contentDisposition: ContentDisposition?
    public let other: [RFC822HeaderField]
}

if let contentTypeString = mime.header.contentType?.raw {
	print("\(contentTypeString)")
	// "text/plain"
}

if case .body(let body) = mime.content {
	print("\(body.raw)")
	// "Test"
}

```

Decoded mime's content is simply to retrieve:

```swift
let content = try mime.decodedContentData()
// "Test"
```

## License

**MimeParser** is available under the MIT license. See the LICENSE file for more info.

## Contribution

**MimeParser** is still very simple and incomplete, so pull requests welcome!
