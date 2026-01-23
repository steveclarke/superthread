# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for board operations.
    class Boards < Base
      desc "list", "List all boards in a space"
      option :space, type: :string, required: true, aliases: "-s", desc: "Space ID or name"
      option :space_id, type: :string, desc: "Space ID (alias for --space)"
      option :bookmarked, type: :boolean, desc: "Filter by bookmarked"
      option :archived, type: :boolean, desc: "Include archived"
      def list
        handle_error do
          boards = client.boards.list(workspace_id, space_id: space_id, **symbolized_options(:bookmarked, :archived))
          output_list boards, columns: %i[id title]
        end
      end

      desc "get BOARD_ID", "Get board details"
      def get(board_id)
        handle_error do
          board = client.boards.find(workspace_id, board_id)
          output_item board, fields: %i[id title description space_id time_created time_updated]
        end
      end

      desc "create", "Create a new board"
      option :space, type: :string, required: true, aliases: "-s", desc: "Space ID or name"
      option :space_id, type: :string, desc: "Space ID (alias for --space)"
      option :title, type: :string, required: true, desc: "Board title"
      option :content, type: :string, desc: "Board description"
      option :icon, type: :string, desc: "Board icon"
      option :color, type: :string, desc: "Board color"
      def create
        handle_error do
          board = client.boards.create(workspace_id, space_id: space_id, **symbolized_options(:title, :content, :icon, :color))
          output_item board
        end
      end

      desc "update BOARD_ID", "Update a board"
      option :title, type: :string, desc: "New title"
      option :content, type: :string, desc: "New description"
      option :icon, type: :string, desc: "New icon"
      option :color, type: :string, desc: "New color"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      def update(board_id)
        handle_error do
          board = client.boards.update(workspace_id, board_id,
                                       **symbolized_options(:title, :content, :icon, :color, :archived))
          output_item board
        end
      end

      desc "duplicate BOARD_ID", "Duplicate a board"
      option :title, type: :string, desc: "Title for the copy"
      option :space, type: :string, aliases: "-s", desc: "Destination space (ID or name)"
      option :space_id, type: :string, desc: "Destination space ID (alias for --space)"
      def duplicate(board_id)
        handle_error do
          opts = symbolized_options(:title)
          opts[:space_id] = space_id if space_id
          board = client.boards.duplicate(workspace_id, board_id, **opts)
          output_item board
        end
      end

      desc "delete BOARD_ID", "Delete a board"
      option :force, type: :boolean, aliases: "-f", desc: "Skip confirmation"
      def delete(board_id)
        handle_error do
          confirming("Delete board #{board_id}?") do
            client.boards.destroy(workspace_id, board_id)
            Ui.success "Board #{board_id} deleted"
          end
        end
      end

      desc "list_create", "Create a list on a board"
      option :board_id, type: :string, required: true, desc: "Board ID"
      option :title, type: :string, required: true, desc: "List title"
      option :content, type: :string, desc: "List description"
      option :icon, type: :string, desc: "List icon"
      option :color, type: :string, desc: "List color"
      def list_create
        handle_error do
          list = client.boards.create_list(workspace_id, **symbolized_options(:board_id, :title, :content, :icon, :color))
          output_item list, fields: %i[id title color board_id]
        end
      end

      desc "list_update LIST_ID", "Update a list"
      option :title, type: :string, desc: "New title"
      option :content, type: :string, desc: "New description"
      option :icon, type: :string, desc: "New icon"
      option :color, type: :string, desc: "New color"
      def list_update(list_id)
        handle_error do
          list = client.boards.update_list(workspace_id, list_id, **symbolized_options(:title, :content, :icon, :color))
          output_item list
        end
      end

      desc "list_delete LIST_ID", "Delete a list"
      option :force, type: :boolean, aliases: "-f", desc: "Skip confirmation"
      def list_delete(list_id)
        handle_error do
          confirming("Delete list #{list_id}?") do
            client.boards.delete_list(workspace_id, list_id)
            Ui.success "List #{list_id} deleted"
          end
        end
      end
    end
  end
end
