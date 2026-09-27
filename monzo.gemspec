# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)
require 'monzo/version'

Gem::Specification.new do |s|
  s.name        = 'monzo'
  s.version     = Monzo::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['n-at-han-k']
  s.homepage    = 'https://github.com/n-at-han-k/openapi-schema-monzo'
  s.summary     = 'OpenAPI 3.1 description of the Monzo Developer API'
  s.description = <<~TEXT
    An OpenAPI 3.1 description of the Monzo Developer API, written from the
    reference at https://docs.monzo.com, plus the conformance suite that checks
    Monzo against it. The gem ships the document; `Monzo::SCHEMA` is its path.
  TEXT
  s.license     = 'LGPL-2.1-or-later'
  s.required_ruby_version = '>= 3.0'
  s.metadata    = {
    'source_code_uri' => 'https://github.com/n-at-han-k/openapi-schema-monzo',
    'documentation_uri' => 'https://docs.monzo.com',
    'rubygems_mfa_required' => 'true'
  }

  s.add_development_dependency 'json_schemer', '~> 2.5'
  s.add_development_dependency 'rspec', '~> 3.13'

  s.files       = ['monzo_api.yaml', 'README.md', 'LICENSE'] + Dir['lib/**/*.rb']
  s.test_files  = Dir['spec/**/*']
  s.executables = []
  s.require_paths = ['lib']
end
