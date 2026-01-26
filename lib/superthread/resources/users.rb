# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for user operations.
    #
    # Provides methods for retrieving user information and
    # listing workspace members via the Superthread API.
    class Users < Base
      # Gets the current authenticated user's account information.
      #
      # @return [Superthread::Models::User] the current user's profile
      def me
        get_object("/users/me", object_class: Models::User, unwrap_key: :user)
      end

      # Gets workspace members.
      #
      # @param workspace_id [String] the workspace identifier
      # @return [Superthread::Objects::Collection<Superthread::Models::User>] the workspace members
      # @note The API uses /teams/:id/members but we use workspace terminology.
      def members(workspace_id)
        ws = safe_id("workspace_id", workspace_id)
        get_collection("/teams/#{ws}/members",
          item_class: Models::User, items_key: :members)
      end
    end
  end
end
