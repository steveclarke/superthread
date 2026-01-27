# frozen_string_literal: true

require "thor"

module Superthread
  # Command-line interface for Superthread project management.
  # Provides Thor-based commands for managing cards, boards, projects, and more.
  module Cli
    # Error raised when a CLI command fails.
    class CommandError < Superthread::Error; end
  end
end
