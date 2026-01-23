# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread team/workspace.
    #
    # @example
    #   user = client.users.me
    #   user.teams.each do |team|
    #     puts "#{team.team_name} (#{team.id})"
    #   end
    #
    class Team < Superthread::Model
      attribute :id, Shale::Type::String
      attribute :team_name, Shale::Type::String
      attribute :sub_domain, Shale::Type::String
      attribute :role, Shale::Type::String
      attribute :status, Shale::Type::String
      attribute :creator_user_id, Shale::Type::String
      attribute :subscription_plan_id, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      # Alias for team_name for consistency.
      #
      # @return [String] Team/workspace name
      def name
        team_name
      end

      # Returns time_created as a Time object.
      #
      # @return [Time, nil] Created time
      def created_at
        ms_to_time(time_created)
      end

      # String representation.
      #
      # @return [String] Team name
      def to_s
        team_name.to_s
      end
    end
  end
end
