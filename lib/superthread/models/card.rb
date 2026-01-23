# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread card (task/issue).
    #
    # @example
    #   card = client.cards.find(workspace_id, card_id)
    #   card.title          # => "Implement feature X"
    #   card.status         # => "started"
    #   card.priority       # => 1
    #   card.priority_name  # => "urgent"
    #   card.members        # => [#<Superthread::Models::Member ...>]
    #   card.archived?      # => false
    #   card.created_at     # => 2024-01-15 10:30:00 -0800
    #
    class Card < Superthread::Model
      # Core identifiers
      attribute :id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :team_id, Shale::Type::String
      attribute :project_id, Shale::Type::String

      # Content
      attribute :title, Shale::Type::String
      attribute :content, Shale::Type::String
      attribute :schema, Shale::Type::Value  # JSON schema, can be complex

      # Status and priority
      attribute :status, Shale::Type::String
      attribute :priority, Shale::Type::Integer
      attribute :estimate, Shale::Type::Float

      # Location
      attribute :board_id, Shale::Type::String
      attribute :board_title, Shale::Type::String
      attribute :list_id, Shale::Type::String
      attribute :list_title, Shale::Type::String
      attribute :list_color, Shale::Type::String
      attribute :sprint_id, Shale::Type::String

      # Ownership
      attribute :owner_id, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :user_id_updated, Shale::Type::String

      # Timestamps (Unix milliseconds)
      attribute :start_date, Shale::Type::Integer
      attribute :due_date, Shale::Type::Integer
      attribute :completed_date, Shale::Type::Integer
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      # Counts
      attribute :total_comments, Shale::Type::Integer
      attribute :total_files, Shale::Type::Integer

      # Flags
      attribute :is_watching, Shale::Type::Boolean
      attribute :is_bookmarked, Shale::Type::Boolean
      attribute :archived_list, Shale::Type::Boolean
      attribute :archived_board, Shale::Type::Boolean

      # Nested collections
      attribute :members, Member, collection: true
      attribute :tags, Tag, collection: true
      attribute :checklists, Checklist, collection: true

      # Archived info (hash with user_id and time_archived)
      attribute :archived, Shale::Type::Value

      # Parent/child relationships use Value type to avoid circular references
      # These are parsed lazily in helper methods
      attribute :parent_card, Shale::Type::Value
      attribute :child_cards, Shale::Type::Value
      attribute :linked_cards, Shale::Type::Value
      attribute :epic, Shale::Type::Value

      # Check if the card is archived.
      #
      # @return [Boolean] True if archived
      def archived?
        !!archived
      end

      # Check if the card is being watched.
      #
      # @return [Boolean] True if watching
      def watching?
        !!is_watching
      end

      # Check if the card is bookmarked.
      #
      # @return [Boolean] True if bookmarked
      def bookmarked?
        !!is_bookmarked
      end

      # Returns start_date as a Time object.
      #
      # @return [Time, nil] Start date
      def start_time
        ms_to_time(start_date)
      end

      # Returns due_date as a Time object.
      #
      # @return [Time, nil] Due date
      def due_time
        ms_to_time(due_date)
      end

      # Returns completed_date as a Time object.
      #
      # @return [Time, nil] Completed date
      def completed_time
        ms_to_time(completed_date)
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

      # Human-readable priority name.
      #
      # @return [String, nil] Priority name
      def priority_name
        {1 => "urgent", 2 => "high", 3 => "medium", 4 => "low"}[priority]
      end

      # String representation.
      #
      # @return [String] Card title
      def to_s
        title.to_s
      end
    end

    # Represents a linked card with relationship type.
    # Extends Card with linked_card_type attribute.
    #
    # @example
    #   linked = card.linked_cards.first
    #   linked.relationship  # => "blocks"
    #   linked.title         # => "Other Card"
    #
    class LinkedCard < Card
      attribute :linked_card_type, Shale::Type::String

      # Alias for linked_card_type.
      #
      # @return [String] Relationship type (blocks, blocked_by, related, duplicates)
      def relationship
        linked_card_type
      end
    end
  end
end
