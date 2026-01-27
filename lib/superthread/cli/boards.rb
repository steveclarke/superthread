# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing Superthread boards.
    #
    # Provides subcommands for listing, creating, updating, and deleting boards,
    # as well as managing board lists (columns).
    class Boards < Base
      desc "list", "List all boards in a space"
      option :space, type: :string, required: true, aliases: "-s", desc: "Space to list boards from (ID or name)"
      option :bookmarked, type: :boolean, desc: "Filter by bookmarked boards"
      option :include_archived, type: :boolean, desc: "Include archived boards"
      # List all boards within a specified space.
      #
      # @return [void]
      def list
        handle_error do
          opts = symbolized_options(:bookmarked)
          opts[:archived] = options[:include_archived] if options[:include_archived]
          boards = client.boards.list(workspace_id, space_id: space_id, **opts)
          output_list boards, columns: %i[id title], headers: {id: "BOARD_ID"}
        end
      end

      desc "get BOARD", "Get board details"
      option :space, type: :string, aliases: "-s", desc: "Space (helps resolve board name)"
      # Display detailed information about a specific board.
      #
      # @param board_ref [String] the board ID or name to retrieve
      # @return [void]
      def get(board_ref)
        handle_error do
          resolved_board_id = resolve_board(board_ref)
          begin
            board = client.boards.find(workspace_id, resolved_board_id)
          rescue Superthread::ForbiddenError, Superthread::NotFoundError
            raise Thor::Error, "Board not found: '#{board_ref}'. Use 'suth boards list -s SPACE' to see available boards."
          end
          output_item board, fields: %i[id title time_created time_updated], labels: {id: "Board ID"}
        end
      end

      # Available layout options for boards.
      LAYOUTS = %w[board list timeline calendar].freeze

      # Available color options for boards and lists.
      COLORS = %w[fog slate grey charcoal black red orange yellow green ocean blue purple pink].freeze

      desc "create", "Create a new board"
      option :space, type: :string, required: true, aliases: "-s", desc: "Space to create board in (ID or name)"
      option :title, type: :string, required: true, desc: "Board title"
      option :description, type: :string, desc: "Board description"
      option :layout, type: :string, enum: LAYOUTS, desc: "Layout: #{LAYOUTS.join(", ")}"
      option :icon, type: :string, desc: "Icon name (e.g., shield, rocket)"
      option :color, type: :string, desc: "Color: #{COLORS.join(", ")}"
      # Create a new board in a space.
      #
      # @return [void]
      def create
        handle_error do
          opts = symbolized_options(:title, :icon, :color, :layout)
          opts[:content] = options[:description] if options[:description]
          board = client.boards.create(workspace_id, space_id: space_id, **opts)
          output_item board, fields: %i[id title time_created], labels: {id: "Board ID"}
        end
      end

      desc "update BOARD", "Update a board"
      option :space, type: :string, aliases: "-s", desc: "Space (helps resolve board name)"
      option :title, type: :string, desc: "New title"
      option :description, type: :string, desc: "New description"
      option :layout, type: :string, enum: LAYOUTS, desc: "Layout: #{LAYOUTS.join(", ")}"
      option :icon, type: :string, desc: "Icon name (e.g., shield, rocket)"
      option :color, type: :string, desc: "Color: #{COLORS.join(", ")}"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      # Update an existing board's properties.
      #
      # @param board_ref [String] the board ID or name to update
      # @return [void]
      def update(board_ref)
        handle_error do
          resolved_board_id = resolve_board(board_ref)
          begin
            opts = symbolized_options(:title, :icon, :color, :layout, :archived)
            opts[:content] = options[:description] if options[:description]
            board = client.boards.update(workspace_id, resolved_board_id, **opts)
          rescue Superthread::ForbiddenError, Superthread::NotFoundError
            raise Thor::Error, "Board not found: '#{board_ref}'. Use 'suth boards list -s SPACE' to see available boards."
          end
          output_item board, fields: %i[id title time_created time_updated], labels: {id: "Board ID"}
        end
      end

      desc "duplicate BOARD", "Duplicate a board"
      option :space, type: :string, required: true, aliases: "-s", desc: "Destination space (ID or name)"
      option :title, type: :string, desc: "Title for the duplicated board"
      option :copy_cards, type: :boolean, default: false, desc: "Copy cards from source board"
      option :create_missing_tags, type: :boolean, default: false, desc: "Create missing tags in target space"
      # Create a copy of an existing board in a specified space.
      #
      # @param board_ref [String] the board ID or name to duplicate
      # @return [void]
      def duplicate(board_ref)
        handle_error do
          resolved_board_id = resolve_board(board_ref)
          begin
            opts = symbolized_options(:title, :copy_cards, :create_missing_tags)
            board = client.boards.duplicate(workspace_id, resolved_board_id, space_id: space_id, **opts)
          rescue Superthread::ForbiddenError, Superthread::NotFoundError
            raise Thor::Error, "Board not found: '#{board_ref}'. Use 'suth boards list -s SPACE' to see available boards."
          end
          output_item board, fields: %i[id title time_created], labels: {id: "Board ID"}
        end
      end

      desc "delete BOARD", "Delete a board"
      option :space, type: :string, aliases: "-s", desc: "Space (helps resolve board name)"
      # Permanently delete a board after confirmation.
      #
      # @param board_ref [String] the board ID or name to delete
      # @return [void]
      def delete(board_ref)
        handle_error do
          resolved_board_id = resolve_board(board_ref)
          begin
            board = client.boards.find(workspace_id, resolved_board_id)
          rescue Superthread::ForbiddenError, Superthread::NotFoundError
            raise Thor::Error, "Board not found: '#{board_ref}'. Use 'suth boards list -s SPACE' to see available boards."
          end
          confirming("Delete board '#{board.title}' (#{board.id})?") do
            client.boards.destroy(workspace_id, board.id)
            output_success "Board '#{board.title}' deleted"
          end
        end
      end
    end
  end
end
