# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread sprint.
    #
    # @example
    #   sprint = client.sprints.find(workspace_id, sprint_id)
    #   sprint.title       # => "Sprint 42"
    #   sprint.status      # => "active"
    #   sprint.active?     # => true
    #
    class Sprint < Superthread::Model
      attribute :id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :team_id, Shale::Type::String
      attribute :space_id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :description, Shale::Type::String
      attribute :status, Shale::Type::String
      attribute :start_date, Shale::Type::Integer
      attribute :due_date, Shale::Type::Integer
      attribute :user_id, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      # Check if sprint is active.
      #
      # @return [Boolean] True if active
      def active?
        status == "active"
      end

      # Check if sprint is complete.
      #
      # @return [Boolean] True if complete
      def complete?
        status == "complete"
      end

      # Check if sprint is planned (not started).
      #
      # @return [Boolean] True if planned
      def planned?
        status == "planned"
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

      # String representation.
      #
      # @return [String] Sprint title
      def to_s
        title.to_s
      end
    end
  end
end
