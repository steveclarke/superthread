# frozen_string_literal: true

module Superthread
  module Resources
    class Users < Base
      # Gets the current user's account information.
      # API: GET /users/me
      #
      # @return [Hash] User account information
      def me
        get("/users/me")
      end

      # Gets workspace members.
      # API: GET /teams/:workspace/members
      #
      # @param workspace_id [String] Workspace ID
      # @return [Hash] List of workspace members
      def members(workspace_id)
        path = workspace_path(workspace_id, "/members")
        # Note: API uses /teams/:id/members but we use workspace terminology
        get("/teams/#{safe_id('workspace_id', workspace_id)}/members")
      end
    end
  end
end
