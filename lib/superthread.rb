# frozen_string_literal: true

# Define module and base errors before Zeitwerk setup
module Superthread
  class Error < StandardError; end
  class ConfigurationError < Error; end
end

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup
loader.eager_load_namespace(Superthread::Cli)
