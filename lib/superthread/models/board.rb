# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread board.
    #
    # @example
    #   board = client.boards.find(workspace_id, board_id)
    #   board.title              # => "Sprint Backlog"
    #   board.lists              # => [#<Superthread::Models::List ...>]
    #   board.lists.first.title  # => "To Do"
    #   board.archived?          # => false
    #
    class Board < Superthread::Model
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

      attribute :id, Shale::Type::String
      attribute :team_id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      # Nested lists
      attribute :lists, List, collection: true

      # Archived info (hash with user_id and time_archived)
      attribute :archived, Shale::Type::Value

      timestamps :time_created, :time_updated
    end
  end
end
