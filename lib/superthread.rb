# frozen_string_literal: true

# Define module and base errors before Zeitwerk setup
module Superthread
  class Error < StandardError; end
  class ConfigurationError < Error; end
end

require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.ignore(File.join(__dir__, 'superthread', 'error.rb'))
loader.setup
loader.eager_load_namespace(Superthread::Cli)
loader.eager_load_namespace(Superthread::Objects)

require_relative 'superthread/error'
