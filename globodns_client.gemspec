# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'globodns_client/version'

Gem::Specification.new do |spec|
  spec.name          = "globodns_client"
  spec.version       = GlobodnsClient::VERSION
  spec.authors       = ["Ernesto Thorp"]
  spec.email         = ["ernesto@corp.globo.com"]

  spec.summary       = %q{Simple client for GloboDNS API.}
  spec.description   = %q{Simple client for GloboDNS API.}
  spec.homepage      = "https://github.com/globocom/globodns-client-ruby"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rest-client"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "test-unit"
end
