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

      # Check if the list is archived.
      #
      # @return [Boolean] True if archived
      def archived?
        !!archived
      end

      # Returns time_created as a Time object.
      #
      # @return [Time, nil] Created time
      def created_at
        ms_to_time(time_created)
      end

      # Returns time_updated as a Time object.
      #
      # @return [Time, nil] Updated time
      def updated_at
        ms_to_time(time_updated)
      end

      # String representation.
      #
      # @return [String] List title
      def to_s
        title.to_s
      end
    end
  end
end
