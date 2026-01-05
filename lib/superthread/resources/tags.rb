# frozen_string_literal: true

module Superthread
  module Resources
    class Tags < Base
      # Creates a new tag.
      # API: POST /:workspace/tags (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param name [String] Tag name
      # @param color [String] Tag color (hex string)
      # @param space_id [String] Optional space ID
      # @return [Hash] Created tag
      def create(workspace_id, name:, color:, space_id: nil)
        ws = safe_id("workspace_id", workspace_id)
        body = build_params(name: name, color: color, project_id: space_id)
        http_post("/#{ws}/tags", body: body)
      end

      # Updates a tag.
      # API: PATCH /:workspace/tags/:tag (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param tag_id [String] Tag ID
      # @param params [Hash] Update parameters (name, color)
      # @return [Hash] Updated tag
      def update(workspace_id, tag_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        tag = safe_id("tag_id", tag_id)
        http_patch("/#{ws}/tags/#{tag}", body: build_params(**params))
      end

      # Deletes a tag.
      # API: DELETE /:workspace/tags/:tag (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param tag_id [String] Tag ID
      # @return [Hash] Success response
      def destroy(workspace_id, tag_id)
        ws = safe_id("workspace_id", workspace_id)
        tag = safe_id("tag_id", tag_id)
        http_delete("/#{ws}/tags/#{tag}")
      end
    end
  end
end
