Pod::Spec.new do |s|
  s.name         = "MimeParser"
  s.version      = "0.2.3"
  s.summary      = "Mime parsing in Swift | Relevant RFCs: RFC 822, RFC 2045, RFC 2046"

  s.description  = <<-DESC
    MimeParser is a simple MIME (Multipurpose Internet Mail Extensions) parsing library written in Swift.
                   DESC

  s.homepage     = "https://github.com/miximka/MimeParser"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = "miximka"

  s.ios.deployment_target = "10.3"
  s.osx.deployment_target = "10.12"

  s.source       = { :git => "https://github.com/miximka/MimeParser.git", :tag => "#{s.version}" }
  s.source_files  = "Sources/MimeParser/*.swift"
end
