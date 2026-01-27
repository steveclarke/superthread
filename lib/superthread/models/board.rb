# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread board.
    #
    # Boards are containers for lists (columns) that organize cards in a
    # Kanban-style workflow. Each board belongs to a team/workspace.
    #
    # @example
    #   board = client.boards.find(workspace_id, board_id)
    #   board.title              # => "Sprint Backlog"
    #   board.lists              # => [#<Superthread::Models::List ...>]
    #   board.lists.first.title  # => "To Do"
    #   board.archived?          # => false
    class Board < Superthread::Model
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

      # @!attribute [rw] id
      #   @return [String] unique board identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] team_id
      #   @return [String] ID of the team/workspace this board belongs to
      attribute :team_id, Shale::Type::String

      # @!attribute [rw] title
      #   @return [String] display title of the board
      attribute :title, Shale::Type::String

      # @!attribute [rw] user_id
      #   @return [String] ID of the user who created the board
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the board was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the board was last updated
      attribute :time_updated, Shale::Type::Integer

      # @!attribute [rw] lists
      #   @return [Array<List>] columns/lists contained in this board
      attribute :lists, List, collection: true

      # @!attribute [rw] archived
      #   @return [Hash{String => Object}, nil] archive metadata with user_id and time_archived, or nil if not archived
      attribute :archived, Shale::Type::Value

      timestamps :time_created, :time_updated
    end
  end
end
