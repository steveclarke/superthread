# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing Superthread pages (documents).
    #
    # Pages are rich-text documents that can be organized within spaces
    # and nested under parent pages to form a hierarchy.
    class Pages < Base
      desc "list", "List all pages"
      option :space, type: :string, aliases: "-s", desc: "Space to filter by (ID or name)"
      option :include_archived, type: :boolean, desc: "Include archived pages"
      option :updated_recently, type: :boolean, desc: "Filter by recently updated pages"
      # Lists all pages in the current workspace with optional filters.
      #
      # @return [void]
      def list
        opts = symbolized_options(:updated_recently)
        opts[:archived] = options[:include_archived] if options[:include_archived]
        opts[:space_id] = space_id if options[:space]
        pages = client.pages.list(workspace_id, **opts)
        output_list pages, columns: %i[id title], headers: {id: "PAGE_ID"}
      end

      desc "get PAGE", "Get page details"
      # Retrieves and displays details for a specific page.
      #
      # @param page_id [String] numeric ID or URL slug of the page to retrieve
      # @return [void]
      def get(page_id)
        handle_error do
          page = with_not_found("Page not found: '#{page_id}'. Use 'suth pages list' to see available pages.") do
            client.pages.find(workspace_id, page_id)
          end
          output_item page, fields: %i[id title time_created time_updated], labels: {id: "Page ID"}
        end
      end

      desc "create", "Create a new page"
      option :space, type: :string, required: true, aliases: "-s", desc: "Space to create page in (ID or name)"
      option :title, type: :string, desc: "Page title"
      option :content, type: :string, desc: "Page content"
      option :parent_page, type: :string, desc: "Parent page ID"
      option :is_public, type: :boolean, desc: "Make page public"
      # Creates a new page in a space.
      #
      # @return [void]
      def create
        opts = symbolized_options(:title, :content, :is_public)
        opts[:space_id] = space_id
        opts[:parent_page_id] = options[:parent_page] if options[:parent_page]
        page = client.pages.create(workspace_id, **opts)
        output_item page, labels: {id: "Page ID"}
      end

      desc "update PAGE", "Update a page"
      option :title, type: :string, desc: "New title"
      option :is_public, type: :boolean, desc: "Public visibility"
      option :parent_page, type: :string, desc: "Parent page ID"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      # Updates an existing page's properties.
      #
      # @param page_id [String] numeric ID or URL slug of the page to retrieve
      # @return [void]
      def update(page_id)
        handle_error do
          opts = symbolized_options(:title, :is_public, :archived)
          opts[:parent_page_id] = options[:parent_page] if options[:parent_page]
          page = with_not_found("Page not found: '#{page_id}'. Use 'suth pages list' to see available pages.") do
            client.pages.update(workspace_id, page_id, **opts)
          end
          output_item page, labels: {id: "Page ID"}
        end
      end

      desc "duplicate PAGE", "Duplicate a page"
      option :space, type: :string, required: true, aliases: "-s", desc: "Destination space (ID or name)"
      option :title, type: :string, desc: "Title for the duplicated page"
      option :parent_page, type: :string, desc: "Parent page ID"
      # Creates a copy of an existing page in a specified space.
      #
      # @param page_id [String] numeric ID of the source page to duplicate
      # @return [void]
      def duplicate(page_id)
        handle_error do
          opts = symbolized_options(:title)
          opts[:space_id] = space_id
          opts[:parent_page_id] = options[:parent_page] if options[:parent_page]
          page = with_not_found("Page not found: '#{page_id}'. Use 'suth pages list' to see available pages.") do
            client.pages.duplicate(workspace_id, page_id, **opts)
          end
          output_item page, labels: {id: "Page ID"}
        end
      end

      desc "archive PAGE", "Archive a page"
      # Archives a page, hiding it from default views.
      #
      # @param page_id [String] numeric ID or URL slug of the page to retrieve
      # @return [void]
      def archive(page_id)
        handle_error do
          page = with_not_found("Page not found: '#{page_id}'. Use 'suth pages list' to see available pages.") do
            client.pages.archive(workspace_id, page_id)
          end
          output_item page, labels: {id: "Page ID"}
        end
      end

      desc "delete PAGE", "Delete a page permanently"
      # Permanently deletes a page after confirmation.
      #
      # @param page_ref [String] page identifier (ID or name)
      # @return [void]
      def delete(page_ref)
        handle_error do
          page = with_not_found("Page not found: '#{page_ref}'. Use 'suth pages list' to see available pages.") do
            client.pages.find(workspace_id, page_ref)
          end
          confirming("Delete page '#{page.title}' (#{page.id})?") do
            client.pages.destroy(workspace_id, page.id)
            output_success "Page '#{page.title}' deleted"
          end
        end
      end
    end
  end
end
