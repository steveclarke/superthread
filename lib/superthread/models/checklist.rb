# frozen_string_literal: true

module Superthread
  module Models
    # Represents a checklist on a card.
    #
    # Checklists contain a collection of items that can be checked off.
    # They track progress and provide completion statistics.
    #
    # @example
    #   checklist = card.checklists.first
    #   checklist.title                    # => "Requirements"
    #   checklist.items.count              # => 3
    #   checklist.items.first.title        # => "Write specs"
    #   checklist.items.first.checked?     # => true
    #   checklist.progress                 # => 66.7
    class Checklist < Superthread::Model
      include Concerns::Presentable
      include Concerns::Timestampable

      presents_as(:title) { "#{title} (#{completed_count}/#{total_count})" }

      # @!attribute [rw] id
      #   @return [String] unique checklist identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] title
      #   @return [String] display title of the checklist
      attribute :title, Shale::Type::String

      # @!attribute [rw] content
      #   @return [String] optional description or notes
      attribute :content, Shale::Type::String

      # @!attribute [rw] card_id
      #   @return [String] ID of the card this checklist belongs to
      attribute :card_id, Shale::Type::String

      # @!attribute [rw] user_id
      #   @return [String] ID of the user who created the checklist
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the checklist was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the checklist was last updated
      attribute :time_updated, Shale::Type::Integer

      # @!attribute [rw] items
      #   @return [Array<ChecklistItem>] items in this checklist
      attribute :items, ChecklistItem, collection: true

      timestamps :time_created, :time_updated

      # Count of completed items.
      #
      # @return [Integer] Number of checked items
      def completed_count
        (items || []).count(&:checked?)
      end

      # Total number of items.
      #
      # @return [Integer] Total items
      def total_count
        (items || []).count
      end

      # Progress as a percentage.
      #
      # @return [Float] Percentage complete (0.0 - 100.0)
      def progress
        return 0.0 if total_count.zero?

        (completed_count.to_f / total_count * 100).round(1)
      end

      # Check if all items are complete.
      #
      # @return [Boolean] True if all items checked
      def complete?
        total_count.positive? && completed_count == total_count
      end
    end
  end
end
