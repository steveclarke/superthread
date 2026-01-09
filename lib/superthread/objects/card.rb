# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a Superthread card (task/issue).
    #
    # @example
    #   card = client.cards.find(workspace_id, card_id)
    #   card.title          # => "Implement feature X"
    #   card.status         # => "started"
    #   card.priority       # => 1
    #   card.members        # => [#<Superthread::Objects::Member ...>]
    #   card.archived?      # => false
    #
    class Card < Superthread::Object
      OBJECT_NAME = 'card'
      Superthread::Object.register_type(OBJECT_NAME, self)

      # Core identifiers
      attr_reader :id, :type, :team_id, :project_id

      # Content
      attr_reader :title, :content, :schema

      # Status and priority
      attr_reader :status, :priority, :estimate

      # Location
      attr_reader :board_id, :board_title, :list_id, :list_title, :list_color, :sprint_id

      # Ownership
      attr_reader :owner_id, :user_id, :user_id_updated

      # Timestamps (Unix milliseconds)
      attr_reader :start_date, :due_date, :completed_date, :time_created, :time_updated

      # Counts
      attr_reader :total_comments, :total_files

      # Flags
      attr_reader :is_watching, :is_bookmarked, :archived_list, :archived_board

      def initialize(data = {})
        super
        # Define attr_readers dynamically for documented fields
        @id = @data[:id]
        @type = @data[:type]
        @team_id = @data[:team_id]
        @project_id = @data[:project_id]
        @title = @data[:title]
        @content = @data[:content]
        @schema = @data[:schema]
        @status = @data[:status]
        @priority = @data[:priority]
        @estimate = @data[:estimate]
        @board_id = @data[:board_id]
        @board_title = @data[:board_title]
        @list_id = @data[:list_id]
        @list_title = @data[:list_title]
        @list_color = @data[:list_color]
        @sprint_id = @data[:sprint_id]
        @owner_id = @data[:owner_id]
        @user_id = @data[:user_id]
        @user_id_updated = @data[:user_id_updated]
        @start_date = @data[:start_date]
        @due_date = @data[:due_date]
        @completed_date = @data[:completed_date]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
        @total_comments = @data[:total_comments]
        @total_files = @data[:total_files]
        @is_watching = @data[:is_watching]
        @is_bookmarked = @data[:is_bookmarked]
        @archived_list = @data[:archived_list]
        @archived_board = @data[:archived_board]
      end

      # Returns members as Member objects.
      #
      # @return [Array<Superthread::Objects::Member>] Card members
      def members
        @members ||= (@data[:members] || []).map { |m| Member.new(m) }
      end

      # Returns checklists as Checklist objects.
      #
      # @return [Array<Superthread::Objects::Checklist>] Card checklists
      def checklists
        @checklists ||= (@data[:checklists] || []).map { |c| Checklist.new(c) }
      end

      # Returns tags as Tag objects.
      #
      # @return [Array<Superthread::Objects::Tag>] Card tags
      def tags
        @tags ||= (@data[:tags] || []).map { |t| Tag.new(t) }
      end

      # Returns child cards as Card objects.
      #
      # @return [Array<Superthread::Objects::Card>] Child cards
      def child_cards
        @child_cards ||= (@data[:child_cards] || []).map { |c| Card.new(c) }
      end

      # Returns linked cards as LinkedCard objects.
      #
      # @return [Array<Superthread::Objects::LinkedCard>] Linked cards
      def linked_cards
        @linked_cards ||= (@data[:linked_cards] || []).map { |c| LinkedCard.new(c) }
      end

      # Returns the parent card if present.
      #
      # @return [Superthread::Object, nil] Parent card summary
      def parent_card
        @parent_card ||= @data[:parent_card] && Superthread::Object.new(@data[:parent_card])
      end

      # Returns the epic if present.
      #
      # @return [Superthread::Object, nil] Epic summary
      def epic
        @epic ||= @data[:epic] && Superthread::Object.new(@data[:epic])
      end

      # Returns the card's archive info if archived.
      #
      # @return [Superthread::Object, nil] Archive info with user_id and time_archived
      def archived
        @archived ||= @data[:archived] && Superthread::Object.new(@data[:archived])
      end

      # Check if the card is archived.
      #
      # @return [Boolean] True if archived
      def archived?
        !!@data[:archived]
      end

      # Check if the card is watching.
      #
      # @return [Boolean] True if watching
      def watching?
        !!@is_watching
      end

      # Check if the card is bookmarked.
      #
      # @return [Boolean] True if bookmarked
      def bookmarked?
        !!@is_bookmarked
      end

      # Returns start_date as a Time object.
      #
      # @return [Time, nil] Start date
      def start_time
        @start_date && Time.at(@start_date / 1000.0)
      end

      # Returns due_date as a Time object.
      #
      # @return [Time, nil] Due date
      def due_time
        @due_date && Time.at(@due_date / 1000.0)
      end

      # Returns completed_date as a Time object.
      #
      # @return [Time, nil] Completed date
      def completed_time
        @completed_date && Time.at(@completed_date / 1000.0)
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

      # Human-readable priority name.
      #
      # @return [String, nil] Priority name
      def priority_name
        case @priority
        when 1 then 'urgent'
        when 2 then 'high'
        when 3 then 'medium'
        when 4 then 'low'
        end
      end
    end

    # Represents a card member.
    class Member < Superthread::Object
      attr_reader :user_id, :role, :assigned_date

      def initialize(data = {})
        super
        @user_id = @data[:user_id]
        @role = @data[:role]
        @assigned_date = @data[:assigned_date]
      end

      # Returns assigned_date as a Time object.
      #
      # @return [Time, nil] Assigned date
      def assigned_at
        @assigned_date && Time.at(@assigned_date / 1000.0)
      end
    end

    # Represents a linked card with relationship type.
    class LinkedCard < Card
      attr_reader :linked_card_type

      def initialize(data = {})
        super
        @linked_card_type = @data[:linked_card_type]
      end

      # Alias for linked_card_type.
      #
      # @return [String] Relationship type (blocks, blocked_by, related, duplicates)
      def relationship
        @linked_card_type
      end
    end
  end
end
