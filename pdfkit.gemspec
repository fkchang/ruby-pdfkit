# frozen_string_literal: true

require_relative 'lib/pdfkit/version'

Gem::Specification.new do |spec|
  spec.name = 'ruby-pdfkit'
  spec.version = PDFKit::VERSION
  spec.authors = ['Forrest Chang']
  spec.email = ['fkchang2000@yahoo.com']

  spec.summary = 'Intelligent PDF analysis and manipulation for AI/LLM workflows'
  spec.description = 'A Ruby CLI tool for content-aware PDF splitting and analysis, ' \
                     'designed specifically for AI/LLM workflows that need to process large documents within context limits.'
  spec.homepage = 'https://github.com/fkchang/ruby-pdfkit'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md",
    'rubygems_mfa_required' => 'true',
  }

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z 2>/dev/null`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'hexapdf', '~> 1.4'
  spec.add_dependency 'thor', '~> 1.0'

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.0'
end
