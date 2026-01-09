# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a Superthread board.
    #
    # @example
    #   board = client.boards.find(workspace_id, board_id)
    #   board.title           # => "Sprint Backlog"
    #   board.lists           # => [#<Superthread::Objects::List ...>]
    #   board.lists.first.title  # => "To Do"
    #
    class Board < Superthread::Object
      OBJECT_NAME = 'board'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :id, :type, :team_id, :space_id, :title, :description,
                  :user_id, :time_created, :time_updated

      def initialize(data = {})
        super
        @id = @data[:id]
        @type = @data[:type]
        @team_id = @data[:team_id]
        @space_id = @data[:space_id]
        @title = @data[:title]
        @description = @data[:description]
        @user_id = @data[:user_id]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
      end

      # Returns lists as List objects.
      #
      # @return [Array<Superthread::Objects::List>] Board lists
      def lists
        @lists ||= (@data[:lists] || []).map { |l| List.new(l) }
      end

      # Returns archived info if archived.
      #
      # @return [Superthread::Object, nil] Archive info
      def archived
        @archived ||= @data[:archived] && Superthread::Object.new(@data[:archived])
      end

      # Check if the board is archived.
      #
      # @return [Boolean] True if archived
      def archived?
        !!@data[:archived]
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

    # Represents a list (column) on a board.
    class List < Superthread::Object
      OBJECT_NAME = 'list'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :id, :type, :board_id, :title, :color, :position,
                  :user_id, :time_created, :time_updated

      def initialize(data = {})
        super
        @id = @data[:id]
        @type = @data[:type]
        @board_id = @data[:board_id]
        @title = @data[:title]
        @color = @data[:color]
        @position = @data[:position]
        @user_id = @data[:user_id]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
      end

      # Returns archived info if archived.
      #
      # @return [Superthread::Object, nil] Archive info
      def archived
        @archived ||= @data[:archived] && Superthread::Object.new(@data[:archived])
      end

      # Check if the list is archived.
      #
      # @return [Boolean] True if archived
      def archived?
        !!@data[:archived]
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
