# frozen_string_literal: true

require 'bundler/setup'
require 'superthread'
require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data('<API_KEY>') { ENV.fetch('SUPERTHREAD_API_KEY', 'test_key') }
  config.filter_sensitive_data('<WORKSPACE_ID>') { ENV.fetch('SUPERTHREAD_WORKSPACE_ID', 'test_workspace') }

  # Allow real HTTP for integration tests when explicitly requested
  config.allow_http_connections_when_no_cassette = false
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    # Reset configuration before each test
    Superthread.instance_variable_set(:@configuration, nil)
  end

  # Tag integration tests
  config.define_derived_metadata(file_path: %r{spec/integration}) do |metadata|
    metadata[:integration] = true
  end
end

# Module-level configuration accessor for tests
module Superthread
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
