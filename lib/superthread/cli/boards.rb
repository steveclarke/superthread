# frozen_string_literal: true

module Superthread
  module Cli
    class Boards < Base
      desc "list", "List all boards in a space"
      option :space_id, type: :string, required: true, desc: "Space ID"
      option :bookmarked, type: :boolean, desc: "Filter by bookmarked"
      option :archived, type: :boolean, desc: "Include archived"
      def list
        output client.boards.list(
          workspace_id,
          space_id: options[:space_id],
          bookmarked: options[:bookmarked],
          archived: options[:archived]
        )
      end

      desc "get BOARD_ID", "Get board details"
      def get(board_id)
        output client.boards.find(workspace_id, board_id)
      end

      desc "create", "Create a new board"
      option :space_id, type: :string, required: true, desc: "Space ID"
      option :title, type: :string, required: true, desc: "Board title"
      option :content, type: :string, desc: "Board description"
      option :icon, type: :string, desc: "Board icon"
      option :color, type: :string, desc: "Board color"
      def create
        output client.boards.create(
          workspace_id,
          space_id: options[:space_id],
          title: options[:title],
          content: options[:content],
          icon: options[:icon],
          color: options[:color]
        )
      end

      desc "update BOARD_ID", "Update a board"
      option :title, type: :string, desc: "New title"
      option :content, type: :string, desc: "New description"
      option :icon, type: :string, desc: "New icon"
      option :color, type: :string, desc: "New color"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      def update(board_id)
        output client.boards.update(
          workspace_id,
          board_id,
          **options.slice(:title, :content, :icon, :color, :archived).transform_keys(&:to_sym)
        )
      end

      desc "duplicate BOARD_ID", "Duplicate a board"
      option :title, type: :string, desc: "Title for the copy"
      option :space_id, type: :string, desc: "Destination space"
      def duplicate(board_id)
        output client.boards.duplicate(
          workspace_id, board_id,
          title: options[:title],
          space_id: options[:space_id]
        )
      end

      desc "delete BOARD_ID", "Delete a board"
      def delete(board_id)
        output client.boards.destroy(workspace_id, board_id)
      end

      desc "list_create", "Create a list on a board"
      option :board_id, type: :string, required: true, desc: "Board ID"
      option :title, type: :string, required: true, desc: "List title"
      option :content, type: :string, desc: "List description"
      option :icon, type: :string, desc: "List icon"
      option :color, type: :string, desc: "List color"
      def list_create
        output client.boards.create_list(
          workspace_id,
          board_id: options[:board_id],
          title: options[:title],
          content: options[:content],
          icon: options[:icon],
          color: options[:color]
        )
      end

      desc "list_update LIST_ID", "Update a list"
      option :title, type: :string, desc: "New title"
      option :content, type: :string, desc: "New description"
      option :icon, type: :string, desc: "New icon"
      option :color, type: :string, desc: "New color"
      def list_update(list_id)
        output client.boards.update_list(
          workspace_id,
          list_id,
          **options.slice(:title, :content, :icon, :color).transform_keys(&:to_sym)
        )
      end

      desc "list_delete LIST_ID", "Delete a list"
      def list_delete(list_id)
        output client.boards.delete_list(workspace_id, list_id)
      end
    end
  end
end
