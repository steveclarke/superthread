# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread user.
    #
    # Users are people who can access Superthread workspaces. They have
    # profiles with display names, emails, and avatars, and can be members
    # of multiple teams.
    #
    # @example
    #   user = client.users.me
    #   user.display_name    # => "John Doe"
    #   user.email           # => "john@example.com"
    #   user.id              # => "u123"
    class User < Superthread::Model
      include Concerns::Presentable
      include Concerns::Timestampable

      presents_as :display_name

      # @!attribute [rw] id
      #   @return [String] unique user identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] user_id
      #   @return [String] alternate user identifier (API returns both in different contexts)
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] type
      #   @return [String] user type
      attribute :type, Shale::Type::String

      # @!attribute [rw] display_name
      #   @return [String] user's display name
      attribute :display_name, Shale::Type::String

      # @!attribute [rw] email
      #   @return [String] user's email address
      attribute :email, Shale::Type::String

      # @!attribute [rw] avatar
      #   @return [String] URL to the user's avatar image
      attribute :avatar, Shale::Type::String

      # @!attribute [rw] role
      #   @return [String] user's role within the current context
      attribute :role, Shale::Type::String

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the user account was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the user was last updated
      attribute :time_updated, Shale::Type::Integer

      # @!attribute [rw] teams
      #   @return [Array<Team>] teams/workspaces this user belongs to
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
