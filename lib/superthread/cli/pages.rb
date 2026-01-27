# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing Superthread pages (documents).
    #
    # Pages are rich-text documents that can be organized within spaces
    # and nested under parent pages to form a hierarchy.
    class Pages < Base
      desc "list", "List all pages"
      option :space, type: :string, aliases: "-s", desc: "Filter by space (ID or name)"
      option :archived, type: :boolean, desc: "Include archived"
      option :updated_recently, type: :boolean, desc: "Filter by recently updated"
      # Lists all pages in the current workspace with optional filters.
      #
      # @return [void]
      def list
        opts = symbolized_options(:archived, :updated_recently)
        opts[:space_id] = space_id if options[:space]
        pages = client.pages.list(workspace_id, **opts)
        output_list pages, columns: %i[id title]
      end

      desc "get PAGE_ID", "Get page details"
      # Retrieves and displays details for a specific page.
      #
      # @param page_id [String] numeric ID or URL slug of the page to retrieve
      # @return [void]
      def get(page_id)
        handle_error do
          page = client.pages.find(workspace_id, page_id)
          output_item page, fields: %i[id title time_created time_updated]
        end
      end

      desc "create", "Create a new page"
      option :space, type: :string, required: true, aliases: "-s", desc: "Space (ID or name)"
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
        output_item page
      end

      desc "update PAGE_ID", "Update a page"
      option :title, type: :string, desc: "New title"
      option :is_public, type: :boolean, desc: "Public visibility"
      option :parent_page, type: :string, desc: "Move under page"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      # Updates an existing page's properties.
      #
      # @param page_id [String] numeric ID or URL slug of the page to retrieve
      # @return [void]
      def update(page_id)
        opts = symbolized_options(:title, :is_public, :archived)
        opts[:parent_page_id] = options[:parent_page] if options[:parent_page]
        page = client.pages.update(workspace_id, page_id, **opts)
        output_item page
      end

      desc "duplicate PAGE_ID", "Duplicate a page"
      option :space, type: :string, required: true, aliases: "-s", desc: "Destination space (ID or name)"
      option :title, type: :string, desc: "Title for the copy"
      option :parent_page, type: :string, desc: "Parent page"
      # Creates a copy of an existing page in a specified space.
      #
      # @param page_id [String] numeric ID of the source page to duplicate
      # @return [void]
      def duplicate(page_id)
        opts = symbolized_options(:title)
        opts[:space_id] = space_id
        opts[:parent_page_id] = options[:parent_page] if options[:parent_page]
        page = client.pages.duplicate(workspace_id, page_id, **opts)
        output_item page
      end

      desc "archive PAGE_ID", "Archive a page"
      # Archives a page, hiding it from default views.
      #
      # @param page_id [String] numeric ID or URL slug of the page to retrieve
      # @return [void]
      def archive(page_id)
        page = client.pages.archive(workspace_id, page_id)
        output_item page
      end

      desc "delete PAGE", "Delete a page permanently"
      # Permanently deletes a page after confirmation.
      #
      # @param page_ref [String] page identifier (ID or name)
      # @return [void]
      def delete(page_ref)
        handle_error do
          page = client.pages.find(workspace_id, page_ref)
          confirming("Delete page '#{page.title}' (#{page.id})?") do
            client.pages.destroy(workspace_id, page.id)
            output_success "Page '#{page.title}' deleted"
          end
        end
      end
    end
  end
end
