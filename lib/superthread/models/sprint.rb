# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread sprint.
    #
    # Sprints are time-boxed iterations used for agile planning. Cards
    # can be assigned to sprints to organize work into release cycles.
    #
    # @example
    #   sprint = client.sprints.find(workspace_id, sprint_id)
    #   sprint.title       # => "Sprint 42"
    #   sprint.start_time  # => 2024-01-15 00:00:00 UTC
    class Sprint < Superthread::Model
      include Concerns::Presentable
      include Concerns::Timestampable

      detail_fields :id, :title, :start_date, :time_created, :time_updated
      list_columns :id, :title, :status

      # @!attribute [rw] id
      #   @return [String] unique sprint identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] team_id
      #   @return [String] ID of the team/workspace this sprint belongs to
      attribute :team_id, Shale::Type::String

      # @!attribute [rw] title
      #   @return [String] display title of the sprint
      attribute :title, Shale::Type::String

      # @!attribute [rw] start_date
      #   @return [Integer] Unix timestamp when the sprint starts
      attribute :start_date, Shale::Type::Integer

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the sprint was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the sprint was last updated
      attribute :time_updated, Shale::Type::Integer

      # @!attribute [rw] lists
      #   @return [Array<List>] columns/lists available in this sprint
      attribute :lists, List, collection: true

      timestamps :time_created, :time_updated
      timestamps start_date: :start_time
    end
  end
end
