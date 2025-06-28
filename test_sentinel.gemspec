# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'test_sentinel'
  spec.version       = '0.1.0'
  spec.authors       = ['euglena1215']
  spec.email         = ['teppest1215@gmail.com']
  spec.summary       = 'AI-powered test coverage analysis tool for Rails applications'
  spec.description   = 'Analyzes test coverage gaps using code complexity, git history, and coverage data to prioritize test generation'
  spec.homepage      = 'https://github.com/euglena1215/test-sentinel'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*', 'bin/*', 'README.md']
  spec.bindir        = 'bin'
  spec.executables   = ['test-sentinel']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
