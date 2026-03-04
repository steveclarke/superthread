# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread project (epic/roadmap item).
    #
    # Projects are high-level work items that group related cards together.
    # They have their own timeline with start and due dates.
    #
    # @example
    #   project = client.projects.find(workspace_id, project_id)
    #   project.title       # => "Q4 Planning"
    #   project.status      # => "active"
    #   project.archived?   # => false
    class Project < Superthread::Model
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

      detail_fields :id, :title, :status, :start_date, :due_date
      list_columns :id, :title, :status

      # @!attribute [rw] id
      #   @return [String] unique project identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] type
      #   @return [String] project type
      attribute :type, Shale::Type::String

      # @!attribute [rw] team_id
      #   @return [String] ID of the team/workspace this project belongs to
      attribute :team_id, Shale::Type::String

      # @!attribute [rw] space_id
      #   @return [String] ID of the space this project belongs to
      attribute :space_id, Shale::Type::String

      # @!attribute [rw] title
      #   @return [String] display title of the project
      attribute :title, Shale::Type::String

      # @!attribute [rw] description
      #   @return [String] project description or summary
      attribute :description, Shale::Type::String

      # @!attribute [rw] status
      #   @return [String] project status (e.g., "active", "completed")
      attribute :status, Shale::Type::String

      # @!attribute [rw] icon
      #   @return [String] emoji or icon identifier for the project
      attribute :icon, Shale::Type::String

      # @!attribute [rw] user_id
      #   @return [String] ID of the user who created the project
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] start_date
      #   @return [Integer] Unix timestamp when the project starts
      attribute :start_date, Shale::Type::Integer

      # @!attribute [rw] due_date
      #   @return [Integer] Unix timestamp when the project is due
      attribute :due_date, Shale::Type::Integer

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the project was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the project was last updated
      attribute :time_updated, Shale::Type::Integer

      # @!attribute [rw] archived
      #   @return [Hash{String => Object}, nil] archive metadata with user_id and time_archived
      attribute :archived, Shale::Type::Value

      timestamps :time_created, :time_updated
      timestamps start_date: :start_time, due_date: :due_time
    end
  end
end
