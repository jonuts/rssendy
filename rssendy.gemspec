# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rssendy/version'

Gem::Specification.new do |spec|
  spec.name          = "rssendy"
  spec.version       = RSSendy::VERSION
  spec.authors       = ["jonah honeyman"]
  spec.email         = ["jonah@honeyman.org"]
  spec.summary       = %q{Publish an RSS feed to sendy}
  spec.description   = %q{Download an RSS feed and push an email template into your hosted sendy app}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.6"
  spec.add_dependency "slop", "~> 3.6"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "pry", "~> 0.10"
end
