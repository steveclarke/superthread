# frozen_string_literal: true

module Superthread
  module Models
    # Represents a checklist item.
    #
    # @example
    #   item = checklist.items.first
    #   item.title     # => "Write specs"
    #   item.checked?  # => true
    #
    class ChecklistItem < Superthread::Model
      attribute :id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :content, Shale::Type::String
      attribute :checklist_id, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :checked, Shale::Type::Boolean
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      # Check if the item is checked.
      #
      # @return [Boolean] True if checked
      def checked?
        !!checked
      end

      # Alias for checked?.
      #
      # @return [Boolean] True if complete
      def complete?
        checked?
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
      # @return [String] Title
      def to_s
        title.to_s
      end
    end
  end
end
