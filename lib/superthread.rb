# frozen_string_literal: true

# Ruby client for the Superthread API.
#
# Provides a CLI and programmatic access to Superthread's
# project management features including cards, boards, and sprints.
#
# @example Using the client
#   client = Superthread::Client.new(api_key: "sk_...")
#   cards = client.cards.list(workspace_id)
#
# @see Superthread::Client Main API client
# @see Superthread::Configuration Configuration options
module Superthread
  # Base class for all Superthread errors.
  class Error < StandardError; end

  # Raised when configuration is invalid or missing.
  class ConfigurationError < Error; end
end

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.ignore(File.join(__dir__, "superthread", "error.rb"))
loader.setup
loader.eager_load_namespace(Superthread::Cli)
loader.eager_load_namespace(Superthread::Models)

require_relative "superthread/error"
