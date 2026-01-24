# frozen_string_literal: true

module Superthread
  module Models
    # Represents a card member assignment.
    #
    # @example
    #   member = card.members.first
    #   member.user_id      # => "user-123"
    #   member.role         # => "assignee"
    #   member.assigned_at  # => 2024-01-15 10:30:00 -0800
    #
    class Member < Superthread::Model
      include Concerns::Presentable
      include Concerns::Timestampable

      presents_as :user_id

      attribute :user_id, Shale::Type::String
      attribute :role, Shale::Type::String
      attribute :assigned_date, Shale::Type::Integer

      timestamps assigned_date: :assigned_at
    end
  end
end
