# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Cli
    module Concerns
      # Resolves board references (ID or name) to board IDs.
      #
      # Board resolution is context-dependent: when --space is provided, it
      # searches only within that space. Otherwise, it searches across all
      # spaces in the workspace.
      module BoardResolvable
        extend ActiveSupport::Concern

        private

        # Get the board ID from --board option, resolving name if needed.
        #
        # @return [String, nil] the resolved board ID, or nil if not specified
        def board_id
          resolve_board(options[:board])
        end

        # Resolve a board reference (ID or name) to its ID.
        #
        # @param ref [String, nil] the board ID or name to resolve
        # @return [String, nil] the resolved board ID
        # @raise [Thor::Error] if name is provided but not found
        def resolve_board(ref)
          return ref if ref.nil?
          return ref if looks_like_id?(ref)

          board = find_board_by_name(ref)
          return board.id if board

          raise Thor::Error, "Board not found: '#{ref}'. Use 'suth boards list --space <space>' to see available boards."
        end

        # Find a board by name, searching within space if specified or all spaces.
        #
        # @param name [String] the board name to search for (case-insensitive)
        # @return [Superthread::Models::Board, nil] the board object or nil if not found
        def find_board_by_name(name)
          # If space is specified, search only in that space
          if options[:space]
            @boards_cache ||= client.boards.list(workspace_id, space_id: space_id)
            return @boards_cache.find { |b| b.title&.downcase == name.downcase }
          end

          # Otherwise search across all spaces
          @all_boards_cache ||= load_all_boards
          @all_boards_cache.find { |b| b.title&.downcase == name.downcase }
        end

        # Load all boards from all spaces in the workspace.
        #
        # @return [Array<Superthread::Models::Board>] all accessible boards
        def load_all_boards
          @spaces_cache ||= client.spaces.list(workspace_id)
          @spaces_cache.flat_map do |space|
            client.boards.list(workspace_id, space_id: space.id).to_a
          rescue Superthread::ApiError
            [] # Skip spaces we can't access
          end
        end
      end
    end
  end
end
