# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Cli
    module Concerns
      # Resolves sprint references (ID or name) to sprint IDs.
      #
      # Sprint resolution requires a --space context for name lookups,
      # since sprints belong to spaces.
      module SprintResolvable
        extend ActiveSupport::Concern

        private

        # Get the sprint ID from --sprint option, resolving name if needed.
        #
        # @return [String, nil] the resolved sprint ID, or nil if not specified
        def sprint_id
          resolve_sprint(options[:sprint])
        end

        # Resolve a sprint reference (ID or name) to its ID.
        #
        # @param ref [String, nil] the sprint ID or name to resolve
        # @return [String, nil] the resolved sprint ID
        # @raise [Thor::Error] if name is provided but not found
        def resolve_sprint(ref)
          return ref if ref.nil?
          return ref if looks_like_id?(ref)

          sprint = find_sprint_by_name(ref)
          return sprint.id if sprint

          raise Thor::Error, "Sprint not found: '#{ref}'. Use 'suth sprints list -s <space>' to see available sprints."
        end

        # Find a sprint by name within the current space context.
        #
        # @param name [String] the sprint name to search for (case-insensitive)
        # @return [Superthread::Models::Sprint, nil] the sprint object or nil if not found
        # @raise [Thor::Error] if --space is not provided
        def find_sprint_by_name(name)
          unless options[:space]
            raise Thor::Error, "--space is required to resolve sprint name '#{name}'"
          end

          @sprints_cache ||= client.sprints.list(workspace_id, space_id: space_id)
          @sprints_cache.find { |s| s.title&.downcase == name.downcase }
        end
      end
    end
  end
end
