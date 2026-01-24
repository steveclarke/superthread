# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for user operations.
    class Users < Base
      desc "me", "Show current user account info"
      def me
        user = client.users.me

        if json_output?
          output_item user
        else
          # Show basic user info
          output_item user, fields: %i[display_name email time_created]

          # Show workspaces with roles
          if user.teams&.any?
            say ""
            say "Workspaces:", :cyan
            user.teams.each do |team|
              say "  #{team.team_name} (#{team.id}) - #{team.role}"
            end
          end
        end
      end

      desc "members", "List workspace members"
      def members
        users = client.users.members(workspace_id)
        output_list users, columns: %i[user_id display_name email role]
      end
    end
  end
end
