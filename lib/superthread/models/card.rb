# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread card (task/issue).
    #
    # @example
    #   card = client.cards.find(workspace_id, card_id)
    #   card.title          # => "Implement feature X"
    #   card.status         # => "started"
    #   card.priority       # => 4
    #   card.priority_name  # => "urgent"
    #   card.members        # => [#<Superthread::Models::Member ...>]
    #   card.archived?      # => false
    #   card.created_at     # => 2024-01-15 10:30:00 -0800
    #
    class Card < Superthread::Model
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

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

      # Timestamps (Unix seconds)
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

      timestamps :time_created, :time_updated
      timestamps start_date: :start_time, due_date: :due_time, completed_date: :completed_time

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

      # Human-readable priority name.
      # Priority values: 4=urgent, 3=high, 2=medium, 1=low
      #
      # @return [String, nil] Priority name
      def priority_name
        {4 => "urgent", 3 => "high", 2 => "medium", 1 => "low"}[priority]
      end

      # Returns the parent card as a CardRef, or nil if none.
      #
      # @return [CardRef, nil] Parent card reference
      def parent
        return nil if parent_card.nil? || parent_card.empty?
        CardRef.new(parent_card)
      end

      # Returns child cards as an array of CardRef objects.
      #
      # @return [Array<CardRef>] Child card references
      def children
        return [] if child_cards.nil? || !child_cards.is_a?(Array)
        child_cards.map { |c| CardRef.new(c) }
      end

      # Returns linked cards as an array of LinkedCardRef objects.
      #
      # @return [Array<LinkedCardRef>] Linked card references
      def links
        return [] if linked_cards.nil? || !linked_cards.is_a?(Array)
        linked_cards.map { |c| LinkedCardRef.new(c) }
      end

      # Returns linked cards grouped by relationship type.
      #
      # @return [Hash<String, Array<LinkedCardRef>>] Links grouped by type
      def links_by_type
        links.group_by(&:relationship)
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

    # Lightweight reference to a card (id + title only).
    # Used for parent/child relationships to avoid circular model references.
    #
    # @example
    #   ref = card.parent
    #   ref.id     # => "abc123"
    #   ref.title  # => "Parent Task"
    #   ref.to_s   # => "Parent Task (abc123)"
    #
    class CardRef
      attr_reader :id, :title

      def initialize(data)
        # API returns card_id for child/linked cards, id for parent
        @id = data["card_id"] || data[:card_id] || data["id"] || data[:id]
        @title = data["title"] || data[:title]
      end

      def to_s
        "#{title} (#{id})"
      end
    end

    # Lightweight reference to a linked card with relationship type.
    #
    # @example
    #   ref = card.links.first
    #   ref.relationship  # => "blocks"
    #   ref.to_s          # => "blocks: Task Name (abc123)"
    #
    class LinkedCardRef < CardRef
      attr_reader :relationship

      def initialize(data)
        super
        @relationship = data["linked_card_type"] || data[:linked_card_type]
      end

      def to_s
        "#{title} (#{id})"
      end
    end
  end
end
