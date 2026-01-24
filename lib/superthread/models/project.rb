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
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

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

      timestamps :time_created, :time_updated
      timestamps start_date: :start_time, due_date: :due_time
    end
  end
end
