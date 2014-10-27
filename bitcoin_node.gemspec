# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bitcoin_node/version'

Gem::Specification.new do |spec|
  spec.name          = "bitcoin_node"
  spec.version       = BitcoinNode::VERSION
  spec.authors       = ["simcap"]
  spec.email         = ["simcap@fastmail.com"]
  spec.summary       = %q{Simple node on the p2p bitcoin network}
  spec.description   = %q{Simple node on the p2p bitcoin network}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
