# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for user operations.
    class Users < Base
      # Gets the current user's account information.
      # API: GET /users/me
      #
      # @return [Superthread::Objects::User] User account information
      def me
        get_object('/users/me', object_class: Objects::User, unwrap_key: :user)
      end

      # Gets workspace members.
      # API: GET /teams/:workspace/members
      #
      # @param workspace_id [String] Workspace ID
      # @return [Superthread::Objects::Collection<User>] List of workspace members
      def members(workspace_id)
        ws = safe_id('workspace_id', workspace_id)
        # NOTE: API uses /teams/:id/members but we use workspace terminology
        get_collection("/teams/#{ws}/members",
                       item_class: Objects::User, items_key: :members)
      end
    end
  end
end
