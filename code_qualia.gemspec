# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'code_qualia'
  spec.version       = '0.1.0'
  spec.authors       = ['euglena1215']
  spec.email         = ['teppest1215@gmail.com']
  spec.summary       = 'A tool for communicating developer intuition and code quality perception to AI through configurable parameters'
  spec.description   = 'Code Qualia helps developers express their subjective understanding and feelings about code quality to AI systems by combining quantitative metrics (coverage, complexity, git activity) with configurable weights that reflect development priorities and intuitions.'
  spec.homepage      = 'https://github.com/euglena1215/code-qualia'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*', 'bin/*', 'README.md']
  spec.bindir        = 'bin'
  spec.executables   = ['code-qualia']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
