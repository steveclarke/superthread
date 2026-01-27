# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for space operations.
    #
    # Provides methods for creating, updating, and managing spaces
    # and their members via the Superthread API.
    class Spaces < Base
      # Lists all spaces in a workspace.
      #
      # @param workspace_id [String] the workspace identifier
      # @return [Superthread::Objects::Collection<Superthread::Models::Space>] the spaces in the workspace
      def list(workspace_id)
        ws = safe_id("workspace_id", workspace_id)
        get_collection("/#{ws}/projects",
          item_class: Models::Space, items_key: :projects)
      end

      # Gets a specific space.
      #
      # @param workspace_id [String] the workspace identifier
      # @param space_id [String] the space identifier (maps to project_id in API)
      # @return [Superthread::Models::Space] the space with all attributes
      def find(workspace_id, space_id)
        ws = safe_id("workspace_id", workspace_id)
        space = safe_id("space_id", space_id)
        get_object("/#{ws}/projects/#{space}",
          object_class: Models::Space, unwrap_key: :project)
      end

      # Creates a new space in the workspace.
      #
      # @param workspace_id [String] the workspace identifier
      # @param title [String] the space title
      # @param params [Hash{Symbol => Object}] optional space parameters
      # @option params [String] :description the space description
      # @option params [String] :icon the space icon identifier
      # @return [Superthread::Models::Space] the created space
      def create(workspace_id, title:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = compact_params(title: title, **params)
        post_object("/#{ws}/projects", body: body,
          object_class: Models::Space, unwrap_key: :project)
      end

      # Updates a space's attributes.
      #
      # @param workspace_id [String] the workspace identifier
      # @param space_id [String] the space identifier
      # @param params [Hash{Symbol => Object}] the attributes to update
      # @option params [String] :title the new space title
      # @option params [String] :description the new space description
      # @option params [String] :icon the new space icon identifier
      # @option params [Boolean] :archived whether the space is archived
      # @return [Superthread::Models::Space] the updated space
      def update(workspace_id, space_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        space = safe_id("space_id", space_id)
        # Map archived -> is_archived for API
        body = compact_params(**params)
        body[:is_archived] = body.delete(:archived) if body.key?(:archived)
        patch_object("/#{ws}/projects/#{space}", body: body,
          object_class: Models::Space, unwrap_key: :project)
      end

      # Deletes a space permanently.
      #
      # @param workspace_id [String] the workspace identifier
      # @param space_id [String] the space identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def destroy(workspace_id, space_id)
        ws = safe_id("workspace_id", workspace_id)
        space = safe_id("space_id", space_id)
        http_delete("/#{ws}/projects/#{space}")
        success_response
      end

      # Adds a member to a space.
      #
      # @param workspace_id [String] the workspace identifier
      # @param space_id [String] the space identifier
      # @param user_id [String] the user identifier to add as a member
      # @param role [String] the member role (admin, member, viewer)
      # @return [Superthread::Object] the membership result
      def add_member(workspace_id, space_id, user_id:, role: "member")
        ws = safe_id("workspace_id", workspace_id)
        space = safe_id("space_id", space_id)
        body = {members: [{user_id: user_id, role: role}]}
        post_object("/#{ws}/projects/#{space}/members", body: body)
      end

      # Removes a member from a space.
      #
      # @param workspace_id [String] the workspace identifier
      # @param space_id [String] the space identifier
      # @param user_id [String] the user identifier to remove
      # @return [Superthread::Object] a response object with success: true
      def remove_member(workspace_id, space_id, user_id)
        ws = safe_id("workspace_id", workspace_id)
        space = safe_id("space_id", space_id)
        user = safe_id("user_id", user_id)
        http_delete("/#{ws}/projects/#{space}/members/#{user}")
        success_response
      end
    end
  end
end
