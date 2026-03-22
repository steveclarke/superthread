# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread card (task/issue).
    #
    # Cards are the primary work items in Superthread, containing title,
    # description, assignees, checklists, and other metadata. They live
    # on boards within lists and can be linked to sprints and projects.
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
    class Card < Superthread::Model
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

      # Human-readable labels for priority levels.
      # @return [Hash{Integer => String}]
      PRIORITY_NAMES = {
        4 => "urgent",
        3 => "high",
        2 => "medium",
        1 => "low"
      }.freeze

      detail_fields :id, :title, :status, :priority, :list_title, :board_title, :time_created, :time_updated
      list_columns :id, :title, :status, :priority, :list_title

      # @!attribute [rw] id
      #   @return [String] unique card identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] type
      #   @return [String] card type (e.g., "card", "epic")
      attribute :type, Shale::Type::String

      # @!attribute [rw] team_id
      #   @return [String] ID of the team/workspace this card belongs to
      attribute :team_id, Shale::Type::String

      # @!attribute [rw] project_id
      #   @return [String] ID of the project this card belongs to
      attribute :project_id, Shale::Type::String

      # @!attribute [rw] title
      #   @return [String] display title of the card
      attribute :title, Shale::Type::String

      # @!attribute [rw] content
      #   @return [String] HTML content/description of the card
      attribute :content, Shale::Type::String

      # @!attribute [rw] schema
      #   @return [Object] JSON schema for custom fields, can be complex
      attribute :schema, Shale::Type::Value

      # @!attribute [rw] status
      #   @return [String] workflow status (e.g., "open", "started", "closed")
      attribute :status, Shale::Type::String

      # @!attribute [rw] priority
      #   @return [Integer] priority level (4=urgent, 3=high, 2=medium, 1=low)
      attribute :priority, Shale::Type::Integer

      # @!attribute [rw] estimate
      #   @return [Float] story point or time estimate
      attribute :estimate, Shale::Type::Float

      # @!attribute [rw] board_id
      #   @return [String] ID of the board this card is on
      attribute :board_id, Shale::Type::String

      # @!attribute [rw] board_title
      #   @return [String] title of the board this card is on
      attribute :board_title, Shale::Type::String

      # @!attribute [rw] list_id
      #   @return [String] ID of the list/column this card is in
      attribute :list_id, Shale::Type::String

      # @!attribute [rw] list_title
      #   @return [String] title of the list/column this card is in
      attribute :list_title, Shale::Type::String

      # @!attribute [rw] list_color
      #   @return [String] color of the list/column this card is in
      attribute :list_color, Shale::Type::String

      # @!attribute [rw] sprint_id
      #   @return [String] ID of the sprint this card is assigned to
      attribute :sprint_id, Shale::Type::String

      # @!attribute [rw] owner_id
      #   @return [String] ID of the card owner
      attribute :owner_id, Shale::Type::String

      # @!attribute [rw] user_id
      #   @return [String] ID of the user who created the card
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] user_id_updated
      #   @return [String] ID of the user who last updated the card
      attribute :user_id_updated, Shale::Type::String

      # @!attribute [rw] start_date
      #   @return [Integer] Unix timestamp when work started
      attribute :start_date, Shale::Type::Integer

      # @!attribute [rw] due_date
      #   @return [Integer] Unix timestamp when the card is due
      attribute :due_date, Shale::Type::Integer

      # @!attribute [rw] completed_date
      #   @return [Integer] Unix timestamp when the card was completed
      attribute :completed_date, Shale::Type::Integer

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the card was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the card was last updated
      attribute :time_updated, Shale::Type::Integer

      # @!attribute [rw] total_comments
      #   @return [Integer] number of comments on this card
      attribute :total_comments, Shale::Type::Integer

      # @!attribute [rw] total_files
      #   @return [Integer] number of files attached to this card
      attribute :total_files, Shale::Type::Integer

      # @!attribute [rw] is_watching
      #   @return [Boolean] whether the current user is watching this card
      attribute :is_watching, Shale::Type::Boolean

      # @!attribute [rw] is_bookmarked
      #   @return [Boolean] whether the current user has bookmarked this card
      attribute :is_bookmarked, Shale::Type::Boolean

      # @!attribute [rw] archived_list
      #   @return [Boolean] whether the card's list is archived
      attribute :archived_list, Shale::Type::Boolean

      # @!attribute [rw] archived_board
      #   @return [Boolean] whether the card's board is archived
      attribute :archived_board, Shale::Type::Boolean

      # @!attribute [rw] members
      #   @return [Array<Member>] users assigned to this card
      attribute :members, Member, collection: true

      # @!attribute [rw] tags
      #   @return [Array<Tag>] labels/tags applied to this card
      attribute :tags, Tag, collection: true

      # @!attribute [rw] checklists
      #   @return [Array<Checklist>] checklists attached to this card
      attribute :checklists, Checklist, collection: true

      # @!attribute [rw] archived
      #   @return [Hash{String => Object}, nil] archive metadata with user_id and time_archived
      attribute :archived, Shale::Type::Value

      # @!attribute [rw] parent_card
      #   @return [Hash{String => Object}, nil] raw parent card data, use {#parent} for CardRef
      attribute :parent_card, Shale::Type::Value

      # @!attribute [rw] child_cards
      #   @return [Array<Hash>, nil] raw child card data, use {#children} for CardRef array
      attribute :child_cards, Shale::Type::Value

      # @!attribute [rw] linked_cards
      #   @return [Array<Hash>, nil] raw linked card data, use {#links} for LinkedCardRef array
      attribute :linked_cards, Shale::Type::Value

      # @!attribute [rw] epic
      #   @return [Hash{String => Object}, nil] epic this card belongs to
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
      #
      # @return [String, nil] priority label (urgent, high, medium, low)
      def priority_name
        PRIORITY_NAMES[priority]
      end

      # Returns the parent card as a CardRef, or nil if none.
      #
      # @return [CardRef, nil] lightweight reference to the parent card
      def parent
        return nil if parent_card.nil? || parent_card.empty?
        CardRef.new(parent_card)
      end

      # Returns child cards as an array of CardRef objects.
      #
      # @return [Array<CardRef>] lightweight references to child cards
      def children
        return [] if child_cards.nil? || !child_cards.is_a?(Array)
        child_cards.map { |c| CardRef.new(c) }
      end

      # Returns linked cards as an array of LinkedCardRef objects.
      #
      # @return [Array<LinkedCardRef>] lightweight references to linked cards with relationship types
      def links
        return [] if linked_cards.nil? || !linked_cards.is_a?(Array)
        linked_cards.map { |c| LinkedCardRef.new(c) }
      end

      # Returns linked cards grouped by relationship type.
      #
      # @return [Hash{String => Array<LinkedCardRef>}] links organized by relationship type
      def links_by_type
        links.group_by(&:relationship)
      end
    end

    # Lightweight reference to a card (id + title only).
    #
    # Used for parent/child relationships to avoid circular model references.
    # Provides just enough information to identify and display a card.
    #
    # @example
    #   ref = card.parent
    #   ref.id     # => "abc123"
    #   ref.title  # => "Parent Task"
    #   ref.to_s   # => "Parent Task (abc123)"
    class CardRef
      # @return [String] unique card identifier
      attr_reader :id

      # @return [String] display title of the card
      attr_reader :title

      # Creates a new card reference from API response data.
      #
      # @param data [Hash{String => Object}, Hash{Symbol => Object}] raw card data from API
      def initialize(data)
        # API returns card_id for child/linked cards, id for parent
        @id = data["card_id"] || data[:card_id] || data["id"] || data[:id]
        @title = data["title"] || data[:title]
      end

      # Returns a human-readable string representation.
      #
      # @return [String] title with ID in parentheses
      def to_s
        "#{title} (#{id})"
      end
    end

    # Lightweight reference to a linked card with relationship type.
    #
    # Extends CardRef to include the relationship type indicating how
    # this card relates to another card.
    #
    # @example
    #   ref = card.links.first
    #   ref.relationship  # => "blocks"
    #   ref.to_s          # => "Task Name (abc123)"
    class LinkedCardRef < CardRef
      # @return [String] relationship type (blocks, blocked_by, related, duplicates)
      attr_reader :relationship

      # Creates a new linked card reference from API response data.
      #
      # @param data [Hash{String => Object}, Hash{Symbol => Object}] raw linked card data from API
      def initialize(data)
        super
        @relationship = data["linked_card_type"] || data[:linked_card_type]
      end
    end
  end
end
