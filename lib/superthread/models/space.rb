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
      attribute :id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :team_id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :description, Shale::Type::String
      attribute :icon, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      # Nested members
      attribute :members, Member, collection: true

      # Archived info (hash with user_id and time_archived)
      attribute :archived, Shale::Type::Value

      # Check if the space is archived.
      #
      # @return [Boolean] True if archived
      def archived?
        !!archived
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
      # @return [String] Space title
      def to_s
        title.to_s
      end
    end
  end
end
