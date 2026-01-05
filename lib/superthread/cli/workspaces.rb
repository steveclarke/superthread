# frozen_string_literal: true

module Superthread
  module Cli
    class Workspaces < Base
      desc "list", "List available workspaces"
      def list
        response = client.users.me
        teams = extract_teams(response)

        if teams.empty?
          say "No workspaces found"
          return
        end

        current = Superthread::Configuration.new.workspace

        say "WORKSPACES"
        teams.each do |team|
          marker = (team[:id] == current) ? "*" : " "
          role = team[:role] || "member"
          say "  #{marker} #{team[:id].ljust(20)} #{team[:name].ljust(25)} #{role}"
        end
        say ""
        say "Use 'st workspaces use <ID>' to set default workspace."
      end

      desc "use WORKSPACE_ID", "Set default workspace"
      def use(workspace_id)
        config = Superthread::Configuration.new
        config.save_workspace(workspace_id)
        say_success "Default workspace set to: #{workspace_id}"
        say_info "Saved to: #{config.config_path}"
      end

      desc "current", "Show current default workspace"
      def current
        config = Superthread::Configuration.new
        if config.workspace
          say "Current workspace: #{config.workspace}"
        else
          say "No default workspace set"
          say_info "Use 'st workspaces list' to see available workspaces"
          say_info "Use 'st workspaces use <ID>' to set a default"
        end
      end

      private

      def extract_teams(response)
        # Handle various API response structures
        # The API typically returns user info with team memberships
        teams = response.dig(:user, :teams) ||
          response.dig(:teams) ||
          response.dig(:user, :team_memberships) ||
          []

        teams.map do |team|
          {
            id: team[:team_id] || team[:id],
            name: team[:team_name] || team[:name] || "Unknown",
            role: team[:role]
          }
        end
      end
    end
  end
end
