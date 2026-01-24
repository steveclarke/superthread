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
      include Concerns::Presentable
      include Concerns::Timestampable

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

      timestamps :time_created, :time_updated
      timestamps start_date: :start_time, due_date: :due_time

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
    end
  end
end
