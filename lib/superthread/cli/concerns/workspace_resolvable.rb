# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Cli
    module Concerns
      # Resolves workspace references (ID or name) to workspace IDs.
      #
      # Workspace IDs have a distinct pattern (alphanumeric, starts with letter,
      # 6-21 chars). Name resolution fetches the current user's teams via the
      # API and matches by team_name.
      module WorkspaceResolvable
        extend ActiveSupport::Concern

        private

        # Get the current workspace ID from options, config, or raise error.
        #
        # @return [String] the resolved workspace ID
        # @raise [Thor::Error] if no workspace is configured
        def workspace_id
          ws = options[:workspace] || client.default_workspace
          return resolve_workspace(ws) if ws

          raise Thor::Error,
            "Workspace required. Use --workspace or set SUPERTHREAD_WORKSPACE_ID " \
            "or add workspace to ~/.config/superthread/config.yaml"
        end

        # Resolve a workspace reference (ID or name) to its ID.
        #
        # @param ref [String, nil] the workspace ID or name to resolve
        # @return [String, nil] the resolved workspace ID, or nil if ref is nil
        def resolve_workspace(ref)
          return ref if ref.nil?

          # Workspace IDs look like: t4k7Wa2e (8 chars, alphanumeric, starts with letter)
          # Skip resolution for ID-like values to avoid unnecessary API calls
          return ref if looks_like_workspace_id?(ref)

          # Try name resolution for name-like values
          workspace = find_workspace_by_name(ref)
          return workspace[:id] if workspace

          # Fall back to treating it as an ID (might still work)
          ref
        end

        # Check if a value looks like a workspace ID (alphanumeric, starts with letter).
        #
        # @param value [String] the value to check
        # @return [Boolean] true if it matches workspace ID pattern
        def looks_like_workspace_id?(value)
          # Workspace IDs are typically 8 chars, start with a letter, alphanumeric
          # Also accept test IDs like "test_workspace"
          value.match?(/\A[a-zA-Z][a-zA-Z0-9_]{5,20}\z/)
        end

        # Find a workspace by name from the cached list.
        #
        # @param name [String] the workspace name to search for (case-insensitive)
        # @return [Hash, nil] the workspace hash with :id and :name, or nil if not found
        def find_workspace_by_name(name)
          @workspaces_cache ||= extract_workspaces_from_user
          @workspaces_cache.find { |w| w[:name]&.downcase == name.downcase }
        end

        # Extract workspace list from the current user's teams.
        #
        # @return [Array<Hash{Symbol => String}>] array of workspace hashes with :id and :name
        def extract_workspaces_from_user
          user = client.users.me
          return [] unless user.teams

          user.teams.map do |team|
            {id: team.id, name: team.team_name}
          end
        end
      end
    end
  end
end
