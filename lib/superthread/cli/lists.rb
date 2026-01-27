# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing board lists (columns).
    #
    # Lists are columns on a board that organize cards into workflow stages.
    # This class provides commands to list, create, update, and delete lists.
    class Lists < Base
      # Available color options for lists.
      COLORS = %w[fog slate grey charcoal black red orange yellow green ocean blue purple pink].freeze

      desc "list", "List all lists on a board"
      option :board, type: :string, required: true, aliases: "-b", desc: "Board to list lists from (ID or name)"
      option :space, type: :string, aliases: "-s", desc: "Space (helps resolve board name)"
      # List all lists (columns) on a specified board.
      #
      # @return [void]
      def list
        handle_error do
          begin
            board = client.boards.find(workspace_id, board_id)
          rescue Superthread::ForbiddenError, Superthread::NotFoundError
            raise Thor::Error, "Board not found. Use 'suth boards list -s SPACE' to see available boards."
          end
          if board.lists.nil? || board.lists.empty?
            say "No lists found on this board.", :yellow
          else
            output_list board.lists, columns: %i[id title color], headers: {id: "LIST_ID"}
          end
        end
      end

      desc "get LIST", "Get list details"
      # Display detailed information about a specific list.
      #
      # @param list_id [String] the unique identifier of the list
      # @return [void]
      # @note Lists are fetched via their parent board.
      def get(list_id)
        handle_error do
          # Lists don't have a direct get endpoint; we need to find via board
          # For now, just output the ID - a proper implementation would search boards
          raise Thor::Error, "Direct list lookup not supported. Use 'lists list --board=BOARD_ID' to see lists."
        end
      end

      desc "create", "Create a new list on a board"
      option :board, type: :string, required: true, aliases: "-b", desc: "Board to create list in (ID or name)"
      option :space, type: :string, aliases: "-s", desc: "Space (helps resolve board name)"
      option :title, type: :string, required: true, desc: "List title"
      option :description, type: :string, desc: "List description"
      option :icon, type: :string, desc: "Icon name (e.g., shield, rocket)"
      option :color, type: :string, desc: "Color: #{COLORS.join(", ")}"
      # Add a new list (column) to a board.
      #
      # @return [void]
      def create
        handle_error do
          opts = symbolized_options(:title, :icon, :color)
          opts[:content] = options[:description] if options[:description]
          list = client.boards.create_list(workspace_id, board_id: board_id, **opts)
          output_item list, fields: %i[id title color board_id], labels: {
            id: "List ID",
            board_id: "Board ID"
          }
        end
      end

      desc "update LIST", "Update a list"
      option :title, type: :string, desc: "New title"
      option :description, type: :string, desc: "New description"
      option :icon, type: :string, desc: "Icon name (e.g., shield, rocket)"
      option :color, type: :string, desc: "Color: #{COLORS.join(", ")}"
      # Update an existing list's properties.
      #
      # @param list_id [String] the unique identifier of the list to update
      # @return [void]
      def update(list_id)
        handle_error do
          begin
            opts = symbolized_options(:title, :icon, :color)
            opts[:content] = options[:description] if options[:description]
            list = client.boards.update_list(workspace_id, list_id, **opts)
          rescue Superthread::ForbiddenError, Superthread::NotFoundError
            raise Thor::Error, "List not found: '#{list_id}'. Use 'suth lists list -b BOARD' to see available lists."
          end
          output_item list, fields: %i[id title color board_id], labels: {
            id: "List ID",
            board_id: "Board ID"
          }
        end
      end

      desc "delete LIST", "Delete a list"
      # Permanently delete a list from a board after confirmation.
      #
      # @param list_id [String] the unique identifier of the list to delete
      # @return [void]
      def delete(list_id)
        handle_error do
          confirming("Delete list #{list_id}?") do
            begin
              client.boards.delete_list(workspace_id, list_id)
            rescue Superthread::ForbiddenError, Superthread::NotFoundError
              raise Thor::Error, "List not found: '#{list_id}'. Use 'suth lists list -b BOARD' to see available lists."
            end
            output_success "List #{list_id} deleted"
          end
        end
      end
    end
  end
end
