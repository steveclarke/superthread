# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread sprint.
    #
    # @example
    #   sprint = client.sprints.find(workspace_id, sprint_id)
    #   sprint.title       # => "Sprint 42"
    #   sprint.start_time  # => 2024-01-15 00:00:00 UTC
    #
    class Sprint < Superthread::Model
      include Concerns::Presentable
      include Concerns::Timestampable

      attribute :id, Shale::Type::String
      attribute :team_id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :start_date, Shale::Type::Integer
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      timestamps :time_created, :time_updated
      timestamps start_date: :start_time
    end
  end
end
