# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread team/workspace.
    #
    # Teams are the top-level organizational unit in Superthread. All boards,
    # projects, spaces, and users belong to a team. Users can be members of
    # multiple teams.
    #
    # @example
    #   user = client.users.me
    #   user.teams.each do |team|
    #     puts "#{team.team_name} (#{team.id})"
    #   end
    class Team < Superthread::Model
      include Concerns::Presentable
      include Concerns::Timestampable

      presents_as :team_name

      # @!attribute [rw] id
      #   @return [String] unique team identifier (workspace ID)
      attribute :id, Shale::Type::String

      # @!attribute [rw] team_name
      #   @return [String] display name of the team
      attribute :team_name, Shale::Type::String

      # @!attribute [rw] sub_domain
      #   @return [String] subdomain for the team's Superthread URL
      attribute :sub_domain, Shale::Type::String

      # @!attribute [rw] role
      #   @return [String] current user's role in this team
      attribute :role, Shale::Type::String

      # @!attribute [rw] status
      #   @return [String] team status (e.g., "active")
      attribute :status, Shale::Type::String

      # @!attribute [rw] creator_user_id
      #   @return [String] ID of the user who created the team
      attribute :creator_user_id, Shale::Type::String

      # @!attribute [rw] subscription_plan_id
      #   @return [String] ID of the team's subscription plan
      attribute :subscription_plan_id, Shale::Type::String

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the team was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the team was last updated
      attribute :time_updated, Shale::Type::Integer

      timestamps :time_created

      # Alias for team_name for consistency.
      #
      # @return [String] Team/workspace name
      def name
        team_name
      end
    end
  end
end
