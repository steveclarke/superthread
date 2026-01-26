# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for page (document) operations.
    #
    # Provides methods for creating, updating, and managing pages
    # (documents, wikis) via the Superthread API.
    class Pages < Base
      # Lists all pages in a workspace.
      #
      # @param workspace_id [String] the workspace identifier
      # @param space_id [String, nil] optional space identifier to filter by
      # @param archived [Boolean, nil] when true, includes archived pages
      # @param updated_recently [Boolean, nil] when true, returns only recently updated pages
      # @return [Superthread::Objects::Collection<Superthread::Models::Page>] the pages in the workspace
      def list(workspace_id, space_id: nil, archived: nil, updated_recently: nil)
        ws = safe_id("workspace_id", workspace_id)
        params = compact_params(project_id: space_id, archived: archived, updated_recently: updated_recently)
        get_collection("/#{ws}/pages", params: params,
          item_class: Models::Page, items_key: :pages)
      end

      # Gets a specific page.
      #
      # @param workspace_id [String] the workspace identifier
      # @param page_id [String] the page identifier
      # @return [Superthread::Models::Page] the page with all attributes
      def find(workspace_id, page_id)
        ws = safe_id("workspace_id", workspace_id)
        page = safe_id("page_id", page_id)
        get_object("/#{ws}/pages/#{page}",
          object_class: Models::Page, unwrap_key: :page)
      end

      # Creates a new page in a space.
      #
      # @param workspace_id [String] the workspace identifier
      # @param space_id [String] the space identifier
      # @param params [Hash{Symbol => Object}] page parameters
      # @option params [String] :title the page title
      # @option params [String] :content the page content as HTML
      # @option params [Hash{Symbol => Object}] :schema the content schema for structured content
      # @option params [String] :parent_page_id the parent page identifier for nesting
      # @return [Superthread::Models::Page] the created page
      def create(workspace_id, space_id:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = compact_params(project_id: space_id, **params)
        post_object("/#{ws}/pages", body: body,
          object_class: Models::Page, unwrap_key: :page)
      end

      # Updates a page's attributes.
      #
      # @param workspace_id [String] the workspace identifier
      # @param page_id [String] the page identifier
      # @param params [Hash{Symbol => Object}] the attributes to update
      # @option params [String] :title the new page title
      # @option params [String] :content the new page content as HTML
      # @option params [Boolean] :archived whether the page is archived
      # @option params [String] :parent_page_id the new parent page identifier
      # @return [Superthread::Models::Page] the updated page
      def update(workspace_id, page_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        page = safe_id("page_id", page_id)
        patch_object("/#{ws}/pages/#{page}", body: compact_params(**params),
          object_class: Models::Page, unwrap_key: :page)
      end

      # Duplicates a page to a destination space.
      #
      # @param workspace_id [String] the workspace identifier
      # @param page_id [String] the page identifier to duplicate
      # @param space_id [String] the destination space identifier
      # @param params [Hash{Symbol => Object}] optional duplication parameters
      # @option params [String] :title the title for the duplicated page (defaults to original)
      # @option params [String] :parent_page_id the parent page identifier in the destination
      # @option params [Integer] :position the position index among sibling pages
      # @return [Superthread::Models::Page] the duplicated page
      def duplicate(workspace_id, page_id, space_id:, **params)
        ws = safe_id("workspace_id", workspace_id)
        page = safe_id("page_id", page_id)
        body = compact_params(project_id: space_id, **params)
        post_object("/#{ws}/pages/#{page}/copy", body: body,
          object_class: Models::Page, unwrap_key: :page)
      end

      # Archives a page (soft delete).
      #
      # @param workspace_id [String] the workspace identifier
      # @param page_id [String] the page identifier to archive
      # @return [Superthread::Models::Page] the archived page
      def archive(workspace_id, page_id)
        update(workspace_id, page_id, archived: true)
      end

      # Deletes a page permanently.
      #
      # @param workspace_id [String] the workspace identifier
      # @param page_id [String] the page identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def destroy(workspace_id, page_id)
        ws = safe_id("workspace_id", workspace_id)
        page = safe_id("page_id", page_id)
        http_delete("/#{ws}/pages/#{page}")
        success_response
      end
    end
  end
end
