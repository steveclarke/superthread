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
      include Concerns::Presentable
      include Concerns::Timestampable

      presents_as :display_name

      attribute :id, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :display_name, Shale::Type::String
      attribute :email, Shale::Type::String
      attribute :avatar, Shale::Type::String
      attribute :role, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer
      attribute :teams, Team, collection: true

      timestamps :time_created, :time_updated

      # Returns the user ID, checking both 'id' and 'user_id' fields
      # (API returns different fields in different contexts)
      #
      # @return [String] User ID
      def user_identifier
        id || user_id
      end
    end
  end
end
