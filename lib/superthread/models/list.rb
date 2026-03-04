# frozen_string_literal: true

module Superthread
  module Models
    # Represents a list (column) on a board.
    #
    # Lists are vertical columns on a Kanban board that contain cards.
    # They have a position for ordering and an optional color for visual distinction.
    #
    # @example
    #   list = board.lists.first
    #   list.title      # => "To Do"
    #   list.color      # => "blue"
    #   list.position   # => 0
    #   list.archived?  # => false
    class List < Superthread::Model
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

      detail_fields :id, :title, :color, :position, :board_id
      list_columns :id, :title, :color

      # @!attribute [rw] id
      #   @return [String] unique list identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] type
      #   @return [String] list type
      attribute :type, Shale::Type::String

      # @!attribute [rw] board_id
      #   @return [String] ID of the board this list belongs to
      attribute :board_id, Shale::Type::String

      # @!attribute [rw] title
      #   @return [String] display title of the list
      attribute :title, Shale::Type::String

      # @!attribute [rw] color
      #   @return [String] color code for visual styling
      attribute :color, Shale::Type::String

      # @!attribute [rw] position
      #   @return [Integer] zero-based position for ordering lists on the board
      attribute :position, Shale::Type::Integer

      # @!attribute [rw] user_id
      #   @return [String] ID of the user who created the list
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the list was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the list was last updated
      attribute :time_updated, Shale::Type::Integer

      # @!attribute [rw] archived
      #   @return [Hash{String => Object}, nil] archive metadata with user_id and time_archived
      attribute :archived, Shale::Type::Value

      timestamps :time_created, :time_updated
    end
  end
end
