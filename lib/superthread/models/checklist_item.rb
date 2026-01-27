# frozen_string_literal: true

module Superthread
  module Models
    # Represents a checklist item.
    #
    # Individual todo items within a checklist that can be marked as complete.
    #
    # @example
    #   item = checklist.items.first
    #   item.title     # => "Write specs"
    #   item.checked?  # => true
    class ChecklistItem < Superthread::Model
      include Concerns::Presentable
      include Concerns::Timestampable

      # @!attribute [rw] id
      #   @return [String] unique checklist item identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] title
      #   @return [String] display title of the item
      attribute :title, Shale::Type::String

      # @!attribute [rw] content
      #   @return [String] optional description or notes
      attribute :content, Shale::Type::String

      # @!attribute [rw] checklist_id
      #   @return [String] ID of the parent checklist
      attribute :checklist_id, Shale::Type::String

      # @!attribute [rw] user_id
      #   @return [String] ID of the user who created the item
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] checked
      #   @return [Boolean] whether this item is checked/completed
      attribute :checked, Shale::Type::Boolean

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the item was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the item was last updated
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
