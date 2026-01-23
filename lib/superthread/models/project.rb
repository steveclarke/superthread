# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread project (epic/roadmap item).
    #
    # @example
    #   project = client.projects.find(workspace_id, project_id)
    #   project.title       # => "Q4 Planning"
    #   project.status      # => "active"
    #   project.archived?   # => false
    #
    class Project < Superthread::Model
      attribute :id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :team_id, Shale::Type::String
      attribute :space_id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :description, Shale::Type::String
      attribute :status, Shale::Type::String
      attribute :icon, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :start_date, Shale::Type::Integer
      attribute :due_date, Shale::Type::Integer
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      # Archived info (hash with user_id and time_archived)
      attribute :archived, Shale::Type::Value

      # Check if the project is archived.
      #
      # @return [Boolean] True if archived
      def archived?
        !!archived
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
      # @return [String] Project title
      def to_s
        title.to_s
      end
    end
  end
end
