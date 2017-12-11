## About
**MimeParser** is a simple MIME (Multipurpose Internet Mail Extensions) parsing library written in Swift (to learn more about mimes refer to [RFC 822](https://tools.ietf.org/html/rfc822), [RFC 2045](https://tools.ietf.org/html/rfc2045), [RFC 2046](https://tools.ietf.org/html/rfc2046))

## Installation

tbd

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

Returned `mime` object is a root of the mime tree and provides access to its `header` fields and `content` data:

```swift
let contentTypeString = mime.header.contentType?.raw
// "text/plain"

let content = try mime.decodedContentData()
// "Test"
```

## License

**MimeParser** is available under the MIT license. See the LICENSE file for more info.

## Contribution

**MimeParser** is still very simple and incomplete, so pull requests welcome!
