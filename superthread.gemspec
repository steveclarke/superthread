# frozen_string_literal: true

require_relative 'lib/superthread/version'

Gem::Specification.new do |spec|
  spec.name = 'superthread'
  spec.version = Superthread::VERSION
  spec.authors = ['Steve Clarke']
  spec.email = ['steve@superthread.com']

  spec.summary = 'Ruby client and CLI for Superthread project management'
  spec.description = 'A Ruby gem providing both a library and CLI for interacting with ' \
                     'the Superthread project management API. Manage cards, boards, projects, ' \
                     'documentation, and more.'
  spec.homepage = 'https://github.com/steveclarke/superthread'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir = 'exe'
  spec.executables = %w[st superthread]
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'zeitwerk', '>= 2.6', '< 3.0'
end
