# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for page (document) operations.
    class Pages < Base
      # Lists all pages.
      # API: GET /:workspace/pages
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Optional space ID to filter by
      # @param archived [Boolean] Include archived pages
      # @param updated_recently [Boolean] Filter by recently updated
      # @return [Superthread::Objects::Collection<Page>] List of pages
      def list(workspace_id, space_id: nil, archived: nil, updated_recently: nil)
        ws = safe_id('workspace_id', workspace_id)
        params = compact_params(project_id: space_id, archived: archived, updated_recently: updated_recently)
        get_collection("/#{ws}/pages", params: params,
                                       item_class: Objects::Page, items_key: :pages)
      end

      # Gets a specific page.
      # API: GET /:workspace/pages/:page
      #
      # @param workspace_id [String] Workspace ID
      # @param page_id [String] Page ID
      # @return [Superthread::Objects::Page] Page details
      def find(workspace_id, page_id)
        ws = safe_id('workspace_id', workspace_id)
        page = safe_id('page_id', page_id)
        get_object("/#{ws}/pages/#{page}",
                   object_class: Objects::Page, unwrap_key: :page)
      end

      # Creates a new page.
      # API: POST /:workspace/pages
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @param params [Hash] Page parameters (title, content, schema, etc.)
      # @return [Superthread::Objects::Page] Created page
      def create(workspace_id, space_id:, **params)
        ws = safe_id('workspace_id', workspace_id)
        body = compact_params(project_id: space_id, **params)
        post_object("/#{ws}/pages", body: body,
                                    object_class: Objects::Page, unwrap_key: :page)
      end

      # Updates a page.
      # API: PATCH /:workspace/pages/:page
      #
      # @param workspace_id [String] Workspace ID
      # @param page_id [String] Page ID
      # @param params [Hash] Update parameters
      # @return [Superthread::Objects::Page] Updated page
      def update(workspace_id, page_id, **params)
        ws = safe_id('workspace_id', workspace_id)
        page = safe_id('page_id', page_id)
        patch_object("/#{ws}/pages/#{page}", body: compact_params(**params),
                                             object_class: Objects::Page, unwrap_key: :page)
      end

      # Duplicates a page.
      # API: POST /:workspace/pages/:page/copy
      #
      # @param workspace_id [String] Workspace ID
      # @param page_id [String] Page ID to duplicate
      # @param space_id [String] Destination space ID
      # @param params [Hash] Optional parameters (title, parent_page_id, position)
      # @return [Superthread::Objects::Page] Duplicated page
      def duplicate(workspace_id, page_id, space_id:, **params)
        ws = safe_id('workspace_id', workspace_id)
        page = safe_id('page_id', page_id)
        body = compact_params(project_id: space_id, **params)
        post_object("/#{ws}/pages/#{page}/copy", body: body,
                                                 object_class: Objects::Page, unwrap_key: :page)
      end

      # Archives a page.
      # API: PATCH /:workspace/pages/:page with archived=true
      #
      # @param workspace_id [String] Workspace ID
      # @param page_id [String] Page ID
      # @return [Superthread::Objects::Page] Archived page
      def archive(workspace_id, page_id)
        update(workspace_id, page_id, archived: true)
      end

      # Deletes a page permanently.
      # API: DELETE /:workspace/pages/:page
      #
      # @param workspace_id [String] Workspace ID
      # @param page_id [String] Page ID
      # @return [Superthread::Object] Success response
      def destroy(workspace_id, page_id)
        ws = safe_id('workspace_id', workspace_id)
        page = safe_id('page_id', page_id)
        http_delete("/#{ws}/pages/#{page}")
        success_response
      end
    end
  end
end
