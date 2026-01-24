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
      include Concerns::Presentable
      include Concerns::Timestampable

      attribute :id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :content, Shale::Type::String
      attribute :checklist_id, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :checked, Shale::Type::Boolean
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      timestamps :time_created, :time_updated

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
    end
  end
end
