# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for tag operations.
    #
    # Provides methods for creating, updating, and deleting tags
    # via the Superthread API.
    class Tags < Base
      # Creates a new tag in the workspace.
      #
      # @param workspace_id [String] the workspace identifier
      # @param name [String] the tag name
      # @param color [String] the tag color as hex string (e.g., "#FF5733")
      # @param space_id [String, nil] optional space identifier to scope the tag
      # @return [Superthread::Models::Tag] the created tag
      def create(workspace_id, name:, color:, space_id: nil)
        ws = safe_id("workspace_id", workspace_id)
        body = compact_params(name: name, color: color, project_id: space_id)
        post_object("/#{ws}/tags", body: body,
          object_class: Models::Tag, unwrap_key: :tag)
      end

      # Updates a tag's attributes.
      #
      # @param workspace_id [String] the workspace identifier
      # @param tag_id [String] the tag identifier
      # @param params [Hash{Symbol => Object}] the attributes to update
      # @option params [String] :name the new tag name
      # @option params [String] :color the new tag color as hex string
      # @return [Superthread::Models::Tag] the updated tag
      def update(workspace_id, tag_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        tag = safe_id("tag_id", tag_id)
        patch_object("/#{ws}/tags/#{tag}", body: compact_params(**params),
          object_class: Models::Tag, unwrap_key: :tag)
      end

      # Deletes a tag permanently.
      #
      # @param workspace_id [String] the workspace identifier
      # @param tag_id [String] the tag identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def destroy(workspace_id, tag_id)
        ws = safe_id("workspace_id", workspace_id)
        tag = safe_id("tag_id", tag_id)
        http_delete("/#{ws}/tags/#{tag}")
        success_response
      end
    end
  end
end
