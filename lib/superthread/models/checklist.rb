# frozen_string_literal: true

module Superthread
  module Models
    # Represents a checklist on a card.
    #
    # @example
    #   checklist = card.checklists.first
    #   checklist.title                    # => "Requirements"
    #   checklist.items.count              # => 3
    #   checklist.items.first.title        # => "Write specs"
    #   checklist.items.first.checked?     # => true
    #   checklist.progress                 # => 66.7
    #
    class Checklist < Superthread::Model
      include Concerns::Presentable
      include Concerns::Timestampable

      presents_as(:title) { "#{title} (#{completed_count}/#{total_count})" }

      attribute :id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :content, Shale::Type::String
      attribute :card_id, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer
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
