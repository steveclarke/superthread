# frozen_string_literal: true

require "simplecov"

require "bundler/setup"
require "superthread"
require "webmock/rspec"

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

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
