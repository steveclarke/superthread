# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for workspace management.
    class Workspaces < Base
      desc 'list', 'List available workspaces'
      def list
        user = client.users.me
        teams = extract_teams(user)

        if teams.empty?
          say 'No workspaces found'
          return
        end

        current = Superthread::Configuration.new.workspace

        say 'WORKSPACES'
        teams.each do |team|
          marker = team[:id] == current ? '*' : ' '
          role = team[:role] || 'member'
          say "  #{marker} #{team[:id].to_s.ljust(20)} #{team[:name].to_s.ljust(25)} #{role}"
        end
        say ''
        say "Use 'st workspaces use <ID>' to set default workspace."
      end

      desc 'use WORKSPACE_ID', 'Set default workspace'
      def use(workspace_id)
        config = Superthread::Configuration.new
        config.save_workspace(workspace_id)
        say_success "Default workspace set to: #{workspace_id}"
        say_info "Saved to: #{config.config_path}"
      end

      desc 'current', 'Show current default workspace'
      def current
        config = Superthread::Configuration.new
        if config.workspace
          say "Current workspace: #{config.workspace}"
        else
          say 'No default workspace set'
          say_info "Use 'st workspaces list' to see available workspaces"
          say_info "Use 'st workspaces use <ID>' to set a default"
        end
      end

      private

      def extract_teams(user)
        # Handle various API response structures
        # The API typically returns user info with team memberships
        # Convert to hash for safe navigation since response structure varies
        data = user.to_h

        teams = data.dig(:user, :teams) ||
                data[:teams] ||
                data.dig(:user, :team_memberships) ||
                []

        teams.map do |team|
          {
            id: team[:team_id] || team[:id],
            name: team[:team_name] || team[:name] || 'Unknown',
            role: team[:role]
          }
        end
      end
    end
  end
end
