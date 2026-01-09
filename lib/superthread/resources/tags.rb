# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for tag operations.
    class Tags < Base
      # Creates a new tag.
      # API: POST /:workspace/tags
      #
      # @param workspace_id [String] Workspace ID
      # @param name [String] Tag name
      # @param color [String] Tag color (hex string)
      # @param space_id [String] Optional space ID
      # @return [Superthread::Objects::Tag] Created tag
      def create(workspace_id, name:, color:, space_id: nil)
        ws = safe_id('workspace_id', workspace_id)
        body = compact_params(name: name, color: color, project_id: space_id)
        post_object("/#{ws}/tags", body: body,
                                   object_class: Objects::Tag, unwrap_key: :tag)
      end

      # Updates a tag.
      # API: PATCH /:workspace/tags/:tag
      #
      # @param workspace_id [String] Workspace ID
      # @param tag_id [String] Tag ID
      # @param params [Hash] Update parameters (name, color)
      # @return [Superthread::Objects::Tag] Updated tag
      def update(workspace_id, tag_id, **params)
        ws = safe_id('workspace_id', workspace_id)
        tag = safe_id('tag_id', tag_id)
        patch_object("/#{ws}/tags/#{tag}", body: compact_params(**params),
                                           object_class: Objects::Tag, unwrap_key: :tag)
      end

      # Deletes a tag.
      # API: DELETE /:workspace/tags/:tag
      #
      # @param workspace_id [String] Workspace ID
      # @param tag_id [String] Tag ID
      # @return [Superthread::Object] Success response
      def destroy(workspace_id, tag_id)
        ws = safe_id('workspace_id', workspace_id)
        tag = safe_id('tag_id', tag_id)
        http_delete("/#{ws}/tags/#{tag}")
        success_response
      end
    end
  end
end
