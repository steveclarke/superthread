# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Cli
    module Concerns
      # Resolves tag references (ID or name) to tag IDs.
      #
      # Tag names are often short alphanumeric strings (e.g., "bug", "feature")
      # that would otherwise look like IDs, so name resolution is tried first.
      module TagResolvable
        extend ActiveSupport::Concern

        private

        # Resolve a tag reference (ID or name) to its ID.
        #
        # Tag names are often short alphanumeric strings (e.g., "bug", "feature")
        # that would otherwise look like IDs, so we try name resolution first.
        #
        # @param ref [String, nil] the tag ID or name to resolve
        # @return [String, nil] the resolved tag ID
        # @raise [Thor::Error] if ref doesn't match a tag name and doesn't look like an ID
        def resolve_tag(ref)
          return ref if ref.nil?

          # Try name resolution first (tags commonly have simple names)
          tag = find_tag_by_name(ref)
          return tag.id if tag

          # If not found by name, assume it's an ID
          return ref if looks_like_id?(ref)

          raise Thor::Error, "Tag not found: '#{ref}'. Use 'suth tags list' to see available tags."
        end

        # Find a tag by name from the cached list.
        #
        # @param name [String] the tag name to search for (case-insensitive)
        # @return [Superthread::Models::Tag, nil] the tag object or nil if not found
        def find_tag_by_name(name)
          @tags_cache ||= client.cards.tags(workspace_id, all: true)
          @tags_cache.find { |t| t.name&.downcase == name.downcase }
        end
      end
    end
  end
end
