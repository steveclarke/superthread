# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a Superthread sprint.
    #
    # @example
    #   sprint = client.sprints.find(workspace_id, sprint_id)
    #   sprint.title       # => "Sprint 42"
    #   sprint.status      # => "active"
    #   sprint.active?     # => true
    #
    class Sprint < Superthread::Object
      OBJECT_NAME = 'sprint'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :id, :type, :team_id, :space_id, :title, :description,
                  :status, :start_date, :due_date, :user_id,
                  :time_created, :time_updated

      def initialize(data = {})
        super
        @id = @data[:id]
        @type = @data[:type]
        @team_id = @data[:team_id]
        @space_id = @data[:space_id]
        @title = @data[:title]
        @description = @data[:description]
        @status = @data[:status]
        @start_date = @data[:start_date]
        @due_date = @data[:due_date]
        @user_id = @data[:user_id]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
      end

      # Check if sprint is active.
      #
      # @return [Boolean] True if active
      def active?
        @status == 'active'
      end

      # Check if sprint is complete.
      #
      # @return [Boolean] True if complete
      def complete?
        @status == 'complete'
      end

      # Check if sprint is planned (not started).
      #
      # @return [Boolean] True if planned
      def planned?
        @status == 'planned'
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
