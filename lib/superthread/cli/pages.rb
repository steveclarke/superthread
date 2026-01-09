# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for page (document) operations.
    class Pages < Base
      desc 'list', 'List all pages'
      option :space_id, type: :string, desc: 'Filter by space'
      option :archived, type: :boolean, desc: 'Include archived'
      option :updated_recently, type: :boolean, desc: 'Filter by recently updated'
      def list
        pages = client.pages.list(workspace_id, **symbolized_options(:space_id, :archived, :updated_recently))
        output_list pages, columns: %i[id title space_id]
      end

      desc 'get PAGE_ID', 'Get page details'
      def get(page_id)
        page = client.pages.find(workspace_id, page_id)
        output_item page, fields: %i[id title space_id time_created time_updated]
      end

      desc 'create', 'Create a new page'
      option :space_id, type: :string, required: true, desc: 'Space ID'
      option :title, type: :string, desc: 'Page title'
      option :content, type: :string, desc: 'Page content'
      option :parent_page_id, type: :string, desc: 'Parent page ID'
      option :is_public, type: :boolean, desc: 'Make page public'
      def create
        page = client.pages.create(workspace_id,
                                   **symbolized_options(:space_id, :title, :content, :parent_page_id, :is_public))
        output_item page
      end

      desc 'update PAGE_ID', 'Update a page'
      option :title, type: :string, desc: 'New title'
      option :is_public, type: :boolean, desc: 'Public visibility'
      option :parent_page_id, type: :string, desc: 'Move under page'
      option :archived, type: :boolean, desc: 'Archive/unarchive'
      def update(page_id)
        page = client.pages.update(workspace_id, page_id,
                                   **symbolized_options(:title, :is_public, :parent_page_id, :archived))
        output_item page
      end

      desc 'duplicate PAGE_ID', 'Duplicate a page'
      option :space_id, type: :string, required: true, desc: 'Destination space'
      option :title, type: :string, desc: 'Title for the copy'
      option :parent_page_id, type: :string, desc: 'Parent page'
      def duplicate(page_id)
        page = client.pages.duplicate(workspace_id, page_id,
                                      **symbolized_options(:space_id, :title, :parent_page_id))
        output_item page
      end

      desc 'archive PAGE_ID', 'Archive a page'
      def archive(page_id)
        page = client.pages.archive(workspace_id, page_id)
        output_item page
      end

      desc 'delete PAGE_ID', 'Delete a page permanently'
      def delete(page_id)
        client.pages.destroy(workspace_id, page_id)
        output_success "Page #{page_id} deleted"
      end
    end
  end
end
