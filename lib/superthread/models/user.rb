# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread user.
    #
    # @example
    #   user = client.users.me
    #   user.display_name    # => "John Doe"
    #   user.email           # => "john@example.com"
    #   user.id              # => "u123"
    #
    class User < Superthread::Model
      attribute :user_id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :display_name, Shale::Type::String
      attribute :email, Shale::Type::String
      attribute :avatar, Shale::Type::String
      attribute :role, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer
      attribute :teams, Team, collection: true

      # Alias for user_id for consistency with other objects.
      #
      # @return [String] User ID
      def id
        user_id
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
      # @return [String] Display name
      def to_s
        display_name.to_s
      end
    end
  end
end
