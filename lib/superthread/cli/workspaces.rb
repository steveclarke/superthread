# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for workspace management within the current account.
    class Workspaces < Base
      desc "list", "List available workspaces for current account"
      def list
        user = client.users.me
        teams = extract_teams(user)

        if teams.empty?
          say "No workspaces found"
          return
        end

        cfg = Superthread::Configuration.new
        current = cfg.workspace

        say "WORKSPACES"
        teams.each do |team|
          marker = (team[:id] == current) ? "*" : " "
          role = team[:role] || "member"
          say "  #{marker} #{team[:id].to_s.ljust(20)} #{team[:name].to_s.ljust(25)} #{role}"
        end
        say ""
        say "Use 'suth workspaces use <ID>' to set default workspace."
      end

      desc "use WORKSPACE_ID", "Set default workspace for current account"
      def use(workspace_id)
        cfg = Superthread::Configuration.new

        unless cfg.current_account
          Ui.error "No account selected"
          Ui.muted "Run 'suth setup' to configure an account first"
          return
        end

        cfg.save_account_state(cfg.current_account,
          workspace_id: workspace_id,
          workspace_name: nil) # Could fetch name from API if desired

        say_success "Default workspace set to: #{workspace_id}"
        say_info "Saved to account: #{cfg.current_account}"
      end

      desc "current", "Show current default workspace"
      def current
        cfg = Superthread::Configuration.new

        if cfg.workspace
          say "Current workspace: #{cfg.workspace}"
          say_info "Account: #{cfg.current_account}" if cfg.current_account
        else
          say "No default workspace set"
          say_info "Use 'suth workspaces list' to see available workspaces"
          say_info "Use 'suth workspaces use <ID>' to set a default"
        end
      end

      private

      def extract_teams(user)
        return [] unless user.teams

        user.teams.map do |team|
          {
            id: team.id,
            name: team.team_name || "Unknown",
            role: team.role
          }
        end
      end
    end
  end
end
