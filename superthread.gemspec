# frozen_string_literal: true

require_relative "lib/superthread/version"

Gem::Specification.new do |spec|
  spec.name = "superthread"
  spec.version = Superthread::VERSION
  spec.authors = ["Steve Clarke"]
  spec.email = ["steve@sevenview.ca"]

  spec.summary = "Unofficial Ruby client and CLI for Superthread project management"
  spec.description = "An unofficial Ruby gem providing both a library and CLI for interacting with " \
                     "the Superthread project management API. Manage cards, boards, projects, " \
                     "documentation, and more."
  spec.homepage = "https://github.com/steveclarke/superthread"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob(%w[lib/**/* exe/* LICENSE README.md CHANGELOG.md])

  spec.bindir = "exe"
  spec.executables = %w[suth]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "glamour", "~> 0.2"
  spec.add_dependency "gum", "~> 0.1"
  spec.add_dependency "reverse_markdown", "~> 3.0"
  spec.add_dependency "shale", "~> 1.0"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "unicode-display_width", "~> 3.0"
  spec.add_dependency "zeitwerk", ">= 2.6", "< 3.0"
end
