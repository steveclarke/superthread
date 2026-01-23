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
      attribute :user_id, Shale::Type::String
      attribute :role, Shale::Type::String
      attribute :assigned_date, Shale::Type::Integer

      # Returns assigned_date as a Time object.
      #
      # @return [Time, nil] Assigned date
      def assigned_at
        ms_to_time(assigned_date)
      end

      # String representation.
      #
      # @return [String] User ID
      def to_s
        user_id.to_s
      end
    end
  end
end
