# frozen_string_literal: true

module Superthread
  module Models
    # Represents a card member assignment.
    #
    # Members link users to cards with a specific role (e.g., assignee).
    # They track when the assignment was made.
    #
    # @example
    #   member = card.members.first
    #   member.user_id      # => "user-123"
    #   member.role         # => "assignee"
    #   member.assigned_at  # => 2024-01-15 10:30:00 -0800
    class Member < Superthread::Model
      include Concerns::Presentable
      include Concerns::Timestampable

      presents_as(:display_name) { display_name || user_id }

      # @!attribute [rw] user_id
      #   @return [String] ID of the assigned user
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] display_name
      #   @return [String, nil] display name of the assigned user (enriched client-side)
      attribute :display_name, Shale::Type::String

      # @!attribute [rw] role
      #   @return [String] assignment role (e.g., "assignee")
      attribute :role, Shale::Type::String

      # @!attribute [rw] assigned_date
      #   @return [Integer] Unix timestamp when the user was assigned
      attribute :assigned_date, Shale::Type::Integer

      timestamps assigned_date: :assigned_at
    end
  end
end
