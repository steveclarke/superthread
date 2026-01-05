# frozen_string_literal: true

module Superthread
  module Cli
    class Pages < Base
      desc "list", "List all pages"
      option :space_id, type: :string, desc: "Filter by space"
      option :archived, type: :boolean, desc: "Include archived"
      option :updated_recently, type: :boolean, desc: "Filter by recently updated"
      def list
        output client.pages.list(
          workspace_id,
          space_id: options[:space_id],
          archived: options[:archived],
          updated_recently: options[:updated_recently]
        )
      end

      desc "get PAGE_ID", "Get page details"
      def get(page_id)
        output client.pages.get(workspace_id, page_id)
      end

      desc "create", "Create a new page"
      option :space_id, type: :string, required: true, desc: "Space ID"
      option :title, type: :string, desc: "Page title"
      option :content, type: :string, desc: "Page content"
      option :parent_page_id, type: :string, desc: "Parent page ID"
      option :is_public, type: :boolean, desc: "Make page public"
      def create
        output client.pages.create(
          workspace_id,
          space_id: options[:space_id],
          title: options[:title],
          content: options[:content],
          parent_page_id: options[:parent_page_id],
          is_public: options[:is_public]
        )
      end

      desc "update PAGE_ID", "Update a page"
      option :title, type: :string, desc: "New title"
      option :is_public, type: :boolean, desc: "Public visibility"
      option :parent_page_id, type: :string, desc: "Move under page"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      def update(page_id)
        output client.pages.update(
          workspace_id,
          page_id,
          **options.slice(:title, :is_public, :parent_page_id, :archived).transform_keys(&:to_sym)
        )
      end

      desc "duplicate PAGE_ID", "Duplicate a page"
      option :space_id, type: :string, required: true, desc: "Destination space"
      option :title, type: :string, desc: "Title for the copy"
      option :parent_page_id, type: :string, desc: "Parent page"
      def duplicate(page_id)
        output client.pages.duplicate(
          workspace_id, page_id,
          space_id: options[:space_id],
          title: options[:title],
          parent_page_id: options[:parent_page_id]
        )
      end

      desc "archive PAGE_ID", "Archive a page"
      def archive(page_id)
        output client.pages.archive(workspace_id, page_id)
      end

      desc "delete PAGE_ID", "Delete a page permanently"
      def delete(page_id)
        output client.pages.delete(workspace_id, page_id)
      end
    end
  end
end
