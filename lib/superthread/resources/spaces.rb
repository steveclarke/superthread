# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for space operations.
    class Spaces < Base
      # Lists all spaces in a workspace.
      # API: GET /:workspace/projects
      #
      # @param workspace_id [String] Workspace ID
      # @return [Superthread::Objects::Collection<Space>] List of spaces
      def list(workspace_id)
        ws = safe_id('workspace_id', workspace_id)
        get_collection("/#{ws}/projects",
                       item_class: Objects::Space, items_key: :projects)
      end

      # Gets a specific space.
      # API: GET /:workspace/projects/:space
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID (maps to project_id in API)
      # @return [Superthread::Objects::Space] Space details
      def find(workspace_id, space_id)
        ws = safe_id('workspace_id', workspace_id)
        space = safe_id('space_id', space_id)
        get_object("/#{ws}/projects/#{space}",
                   object_class: Objects::Space, unwrap_key: :project)
      end

      # Creates a new space.
      # API: POST /:workspace/projects
      #
      # @param workspace_id [String] Workspace ID
      # @param title [String] Space title
      # @param params [Hash] Optional parameters (description, icon)
      # @return [Superthread::Objects::Space] Created space
      def create(workspace_id, title:, **params)
        ws = safe_id('workspace_id', workspace_id)
        body = compact_params(title: title, **params)
        post_object("/#{ws}/projects", body: body,
                                       object_class: Objects::Space, unwrap_key: :project)
      end

      # Updates a space.
      # API: PATCH /:workspace/projects/:space
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @param params [Hash] Update parameters
      # @return [Superthread::Objects::Space] Updated space
      def update(workspace_id, space_id, **params)
        ws = safe_id('workspace_id', workspace_id)
        space = safe_id('space_id', space_id)
        patch_object("/#{ws}/projects/#{space}", body: compact_params(**params),
                                                 object_class: Objects::Space, unwrap_key: :project)
      end

      # Deletes a space.
      # API: DELETE /:workspace/projects/:space
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @return [Superthread::Object] Success response
      def destroy(workspace_id, space_id)
        ws = safe_id('workspace_id', workspace_id)
        space = safe_id('space_id', space_id)
        http_delete("/#{ws}/projects/#{space}")
        success_response
      end

      # Adds a member to a space.
      # API: POST /:workspace/projects/:space/members
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @param user_id [String] User ID to add
      # @param role [String] Member role
      # @return [Superthread::Object] Result
      def add_member(workspace_id, space_id, user_id:, role: nil)
        ws = safe_id('workspace_id', workspace_id)
        space = safe_id('space_id', space_id)
        body = compact_params(user_id: user_id, role: role)
        post_object("/#{ws}/projects/#{space}/members", body: body)
      end

      # Removes a member from a space.
      # API: DELETE /:workspace/projects/:space/members/:member
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @param member_id [String] Member ID to remove
      # @return [Superthread::Object] Success response
      def remove_member(workspace_id, space_id, member_id)
        ws = safe_id('workspace_id', workspace_id)
        space = safe_id('space_id', space_id)
        member = safe_id('member_id', member_id)
        http_delete("/#{ws}/projects/#{space}/members/#{member}")
        success_response
      end
    end
  end
end
