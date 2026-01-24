# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for board operations.
    class Boards < Base
      desc "list", "List all boards in a space"
      option :space, type: :string, required: true, aliases: "-s", desc: "Space (ID or name)"
      option :bookmarked, type: :boolean, desc: "Filter by bookmarked"
      option :archived, type: :boolean, desc: "Include archived"
      def list
        handle_error do
          boards = client.boards.list(workspace_id, space_id: space_id, **symbolized_options(:bookmarked, :archived))
          output_list boards, columns: %i[id title]
        end
      end

      desc "get BOARD", "Get board details"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      option :open, type: :boolean, aliases: "-o", desc: "Open in web browser"
      def get(board_ref)
        handle_error do
          resolved_board_id = resolve_board(board_ref)
          board = client.boards.find(workspace_id, resolved_board_id)
          output_item board, fields: %i[id title description space_id time_created time_updated]

          open_in_browser(:board, resolved_board_id)
        end
      end

      desc "lists BOARD", "List columns/lists on a board"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      def lists(board_ref)
        handle_error do
          board = client.boards.find(workspace_id, resolve_board(board_ref))
          if board.lists.nil? || board.lists.empty?
            say "No lists found on this board.", :yellow
          else
            output_list board.lists, columns: %i[id title color]
          end
        end
      end

      desc "create", "Create a new board"
      option :space, type: :string, required: true, aliases: "-s", desc: "Space (ID or name)"
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

      desc "update BOARD", "Update a board"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      option :title, type: :string, desc: "New title"
      option :content, type: :string, desc: "New description"
      option :icon, type: :string, desc: "New icon"
      option :color, type: :string, desc: "New color"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      def update(board_ref)
        handle_error do
          board = client.boards.update(workspace_id, resolve_board(board_ref),
            **symbolized_options(:title, :content, :icon, :color, :archived))
          output_item board
        end
      end

      desc "duplicate BOARD", "Duplicate a board"
      option :space, type: :string, aliases: "-s", desc: "Destination space (ID or name)"
      option :title, type: :string, desc: "Title for the copy"
      def duplicate(board_ref)
        handle_error do
          opts = symbolized_options(:title)
          opts[:space_id] = space_id if space_id
          board = client.boards.duplicate(workspace_id, resolve_board(board_ref), **opts)
          output_item board
        end
      end

      desc "delete BOARD", "Delete a board"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      option :force, type: :boolean, aliases: "-f", desc: "Skip confirmation"
      def delete(board_ref)
        handle_error do
          resolved = resolve_board(board_ref)
          confirming("Delete board #{board_ref}?") do
            client.boards.destroy(workspace_id, resolved)
            Ui.success "Board #{board_ref} deleted"
          end
        end
      end

      desc "create-list", "Create a list on a board"
      option :board, type: :string, required: true, aliases: "-b", desc: "Board (ID or name)"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      option :title, type: :string, required: true, desc: "List title"
      option :content, type: :string, desc: "List description"
      option :icon, type: :string, desc: "List icon"
      option :color, type: :string, desc: "List color"
      def create_list
        handle_error do
          list = client.boards.create_list(workspace_id,
            board_id: board_id, **symbolized_options(:title, :content, :icon, :color))
          output_item list, fields: %i[id title color board_id]
        end
      end

      desc "update-list LIST_ID", "Update a list"
      option :title, type: :string, desc: "New title"
      option :content, type: :string, desc: "New description"
      option :icon, type: :string, desc: "New icon"
      option :color, type: :string, desc: "New color"
      def update_list(list_id)
        handle_error do
          list = client.boards.update_list(workspace_id, list_id, **symbolized_options(:title, :content, :icon, :color))
          output_item list
        end
      end

      desc "delete-list LIST_ID", "Delete a list"
      option :force, type: :boolean, aliases: "-f", desc: "Skip confirmation"
      def delete_list(list_id)
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
