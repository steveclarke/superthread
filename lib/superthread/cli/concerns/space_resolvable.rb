# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Cli
    module Concerns
      # Resolves space references (ID or name) to space IDs.
      #
      # Space resolution tries name lookup first, then falls back to treating
      # the reference as a direct ID. The spaces list is cached per command
      # invocation.
      module SpaceResolvable
        extend ActiveSupport::Concern

        private

        # Get the space ID from --space option, resolving name if needed.
        #
        # @return [String, nil] the resolved space ID, or nil if not specified
        def space_id
          resolve_space(options[:space])
        end

        # Resolve a space reference (ID or name) to its ID.
        #
        # @param ref [String, nil] the space ID or name to resolve
        # @return [String, nil] the resolved space ID
        # @raise [Thor::Error] if name is provided but not found
        def resolve_space(ref)
          return ref if ref.nil?

          # Try name resolution first, then fall back to assuming it's an ID
          space = find_space_by_name(ref)
          return space.id if space

          # Assume it's an ID if name lookup failed
          ref
        end

        # Find a space by name from the cached list.
        #
        # @param name [String] the space name to search for (case-insensitive)
        # @return [Superthread::Models::Space, nil] the space object or nil if not found
        def find_space_by_name(name)
          @spaces_cache ||= client.spaces.list(workspace_id)
          @spaces_cache.find { |s| s.title&.downcase == name.downcase }
        end
      end
    end
  end
end
