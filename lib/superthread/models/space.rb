# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread space.
    #
    # @example
    #   space = client.spaces.find(workspace_id, space_id)
    #   space.title       # => "Engineering"
    #   space.members     # => [#<Superthread::Models::Member ...>]
    #   space.archived?   # => false
    #
    class Space < Superthread::Model
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

      attribute :id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :team_id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :description, Shale::Type::String
      attribute :icon, Shale::Type::Value
      attribute :user_id, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      # Nested members
      attribute :members, Member, collection: true

      # Archived info (hash with user_id and time_archived)
      attribute :archived, Shale::Type::Value

      timestamps :time_created, :time_updated
    end
  end
end
