# frozen_string_literal: true

module Superthread
  module Resources
    class Pages < Base
      # Lists all pages.
      # API: GET /:workspace/pages
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Optional space ID to filter by
      # @param archived [Boolean] Include archived pages
      # @param updated_recently [Boolean] Filter by recently updated
      # @return [Hash] List of pages
      def list(workspace_id, space_id: nil, archived: nil, updated_recently: nil)
        ws = safe_id("workspace_id", workspace_id)
        params = build_params(project_id: space_id, archived: archived, updated_recently: updated_recently)
        get("/#{ws}/pages", params: params)
      end

      # Gets a specific page.
      # API: GET /:workspace/pages/:page
      #
      # @param workspace_id [String] Workspace ID
      # @param page_id [String] Page ID
      # @return [Hash] Page details
      def get(workspace_id, page_id)
        ws = safe_id("workspace_id", workspace_id)
        page = safe_id("page_id", page_id)
        get("/#{ws}/pages/#{page}")
      end

      # Creates a new page.
      # API: POST /:workspace/pages
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @param params [Hash] Page parameters (title, content, schema, etc.)
      # @return [Hash] Created page
      def create(workspace_id, space_id:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = build_params(project_id: space_id, **params)
        post("/#{ws}/pages", body: body)
      end

      # Updates a page.
      # API: PATCH /:workspace/pages/:page
      #
      # @param workspace_id [String] Workspace ID
      # @param page_id [String] Page ID
      # @param params [Hash] Update parameters
      # @return [Hash] Updated page
      def update(workspace_id, page_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        page = safe_id("page_id", page_id)
        patch("/#{ws}/pages/#{page}", body: build_params(**params))
      end

      # Duplicates a page.
      # API: POST /:workspace/pages/:page/copy
      #
      # @param workspace_id [String] Workspace ID
      # @param page_id [String] Page ID to duplicate
      # @param space_id [String] Destination space ID
      # @param params [Hash] Optional parameters (title, parent_page_id, position)
      # @return [Hash] Duplicated page
      def duplicate(workspace_id, page_id, space_id:, **params)
        ws = safe_id("workspace_id", workspace_id)
        page = safe_id("page_id", page_id)
        body = build_params(project_id: space_id, **params)
        post("/#{ws}/pages/#{page}/copy", body: body)
      end

      # Archives a page.
      # API: PATCH /:workspace/pages/:page with archived=true
      #
      # @param workspace_id [String] Workspace ID
      # @param page_id [String] Page ID
      # @return [Hash] Archived page
      def archive(workspace_id, page_id)
        update(workspace_id, page_id, archived: true)
      end

      # Deletes a page permanently.
      # API: DELETE /:workspace/pages/:page
      #
      # @param workspace_id [String] Workspace ID
      # @param page_id [String] Page ID
      # @return [Hash] Success response
      def delete(workspace_id, page_id)
        ws = safe_id("workspace_id", workspace_id)
        page = safe_id("page_id", page_id)
        delete("/#{ws}/pages/#{page}")
      end
    end
  end
end
