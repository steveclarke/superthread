# frozen_string_literal: true

module Superthread
  module Resources
    class Spaces < Base
      # Lists all spaces in a workspace.
      # API: GET /:workspace/projects
      #
      # @param workspace_id [String] Workspace ID
      # @return [Hash] List of spaces
      def list(workspace_id)
        ws = safe_id("workspace_id", workspace_id)
        http_get("/#{ws}/projects")
      end

      # Gets a specific space.
      # API: GET /:workspace/projects/:space
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID (maps to project_id in API)
      # @return [Hash] Space details
      def find(workspace_id, space_id)
        ws = safe_id("workspace_id", workspace_id)
        space = safe_id("space_id", space_id)
        http_get("/#{ws}/projects/#{space}")
      end

      # Creates a new space.
      # API: POST /:workspace/projects
      #
      # @param workspace_id [String] Workspace ID
      # @param title [String] Space title
      # @param params [Hash] Optional parameters (description, icon)
      # @return [Hash] Created space
      def create(workspace_id, title:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = build_params(title: title, **params)
        http_post("/#{ws}/projects", body: body)
      end

      # Updates a space.
      # API: PATCH /:workspace/projects/:space
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @param params [Hash] Update parameters
      # @return [Hash] Updated space
      def update(workspace_id, space_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        space = safe_id("space_id", space_id)
        http_patch("/#{ws}/projects/#{space}", body: build_params(**params))
      end

      # Deletes a space.
      # API: DELETE /:workspace/projects/:space
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @return [Hash] Success response
      def destroy(workspace_id, space_id)
        ws = safe_id("workspace_id", workspace_id)
        space = safe_id("space_id", space_id)
        http_delete("/#{ws}/projects/#{space}")
      end

      # Adds a member to a space.
      # API: POST /:workspace/projects/:space/members
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @param user_id [String] User ID to add
      # @param role [String] Member role
      # @return [Hash] Result
      def add_member(workspace_id, space_id, user_id:, role: nil)
        ws = safe_id("workspace_id", workspace_id)
        space = safe_id("space_id", space_id)
        body = build_params(user_id: user_id, role: role)
        http_post("/#{ws}/projects/#{space}/members", body: body)
      end

      # Removes a member from a space.
      # API: DELETE /:workspace/projects/:space/members/:member
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @param member_id [String] Member ID to remove
      # @return [Hash] Success response
      def remove_member(workspace_id, space_id, member_id)
        ws = safe_id("workspace_id", workspace_id)
        space = safe_id("space_id", space_id)
        member = safe_id("member_id", member_id)
        http_delete("/#{ws}/projects/#{space}/members/#{member}")
      end
    end
  end
end
