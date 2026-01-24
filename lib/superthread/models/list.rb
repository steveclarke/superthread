# frozen_string_literal: true

module Superthread
  module Models
    # Represents a list (column) on a board.
    #
    # @example
    #   list = board.lists.first
    #   list.title      # => "To Do"
    #   list.color      # => "blue"
    #   list.position   # => 0
    #   list.archived?  # => false
    #
    class List < Superthread::Model
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

      attribute :id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :board_id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :color, Shale::Type::String
      attribute :position, Shale::Type::Integer
      attribute :user_id, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      # Archived info (hash with user_id and time_archived)
      attribute :archived, Shale::Type::Value

      timestamps :time_created, :time_updated
    end
  end
end
