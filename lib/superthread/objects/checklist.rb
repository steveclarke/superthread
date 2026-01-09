# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a checklist on a card.
    #
    # @example
    #   checklist = card.checklists.first
    #   checklist.title                    # => "Requirements"
    #   checklist.items.count              # => 3
    #   checklist.items.first.title        # => "Write specs"
    #   checklist.items.first.checked?     # => true
    #
    class Checklist < Superthread::Object
      OBJECT_NAME = 'checklist'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :id, :title, :content, :card_id, :user_id, :time_created, :time_updated

      def initialize(data = {})
        super
        @id = @data[:id]
        @title = @data[:title]
        @content = @data[:content]
        @card_id = @data[:card_id]
        @user_id = @data[:user_id]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
      end

      # Returns items as ChecklistItem objects.
      #
      # @return [Array<Superthread::Objects::ChecklistItem>] Checklist items
      def items
        @items ||= (@data[:items] || []).map { |i| ChecklistItem.new(i) }
      end

      # Returns time_created as a Time object.
      #
      # @return [Time, nil] Created time
      def created_at
        @time_created && Time.at(@time_created / 1000.0)
      end

      # Returns time_updated as a Time object.
      #
      # @return [Time, nil] Updated time
      def updated_at
        @time_updated && Time.at(@time_updated / 1000.0)
      end

      # Count of completed items.
      #
      # @return [Integer] Number of checked items
      def completed_count
        items.count(&:checked?)
      end

      # Total number of items.
      #
      # @return [Integer] Total items
      def total_count
        items.count
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

    # Represents a checklist item.
    class ChecklistItem < Superthread::Object
      OBJECT_NAME = 'checklist_item'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :id, :title, :content, :checklist_id, :user_id, :checked, :time_created, :time_updated

      def initialize(data = {})
        super
        @id = @data[:id]
        @title = @data[:title]
        @content = @data[:content]
        @checklist_id = @data[:checklist_id]
        @user_id = @data[:user_id]
        @checked = @data[:checked]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
      end

      # Check if the item is checked.
      #
      # @return [Boolean] True if checked
      def checked?
        !!@checked
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
        @time_created && Time.at(@time_created / 1000.0)
      end

      # Returns time_updated as a Time object.
      #
      # @return [Time, nil] Updated time
      def updated_at
        @time_updated && Time.at(@time_updated / 1000.0)
      end
    end
  end
end
