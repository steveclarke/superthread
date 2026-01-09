# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a Superthread project.
    #
    # @example
    #   project = client.projects.find(workspace_id, project_id)
    #   project.title       # => "Q4 Planning"
    #   project.status      # => "active"
    #
    class Project < Superthread::Object
      OBJECT_NAME = 'project'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :id, :type, :team_id, :space_id, :title, :description,
                  :status, :icon, :user_id, :start_date, :due_date,
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
        @icon = @data[:icon]
        @user_id = @data[:user_id]
        @start_date = @data[:start_date]
        @due_date = @data[:due_date]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
      end

      # Returns archived info if archived.
      #
      # @return [Superthread::Object, nil] Archive info
      def archived
        @archived ||= @data[:archived] && Superthread::Object.new(@data[:archived])
      end

      # Check if the project is archived.
      #
      # @return [Boolean] True if archived
      def archived?
        !!@data[:archived]
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
