# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for workspace management within the current account.
    class Workspaces < Base
      desc "list", "List available workspaces for current account"
      # Lists all workspaces available to the current account.
      #
      # @return [void]
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

      desc "use WORKSPACE", "Set default workspace for current account"
      # Sets the default workspace for the current account.
      #
      # @param workspace_ref [String] workspace ID or name to switch to
      # @return [void]
      def use(workspace_ref)
        handle_error do
          cfg = Superthread::Configuration.new

          unless cfg.current_account
            Ui.error "No account selected"
            Ui.muted "Run 'suth setup' to configure an account first"
            return
          end

          # Fetch workspaces and resolve the reference
          user = client.users.me
          teams = extract_teams(user)

          workspace = teams.find { |t| t[:id] == workspace_ref || t[:name] == workspace_ref }

          unless workspace
            Ui.error "Workspace '#{workspace_ref}' not found"
            Ui.muted "Available workspaces:"
            teams.each { |t| Ui.muted "  #{t[:id]} - #{t[:name]}" }
            return
          end

          cfg.save_account_state(cfg.current_account,
            workspace_id: workspace[:id],
            workspace_name: workspace[:name])

          Ui.success "Default workspace set to: #{workspace[:name]} (#{workspace[:id]})"
        end
      end

      desc "current", "Show current default workspace"
      # Displays the currently selected default workspace.
      #
      # @return [void]
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

      # Extract team/workspace information from a user object.
      #
      # @param user [Superthread::Models::User] the user object with teams data
      # @return [Array<Hash{Symbol => String}>] array of workspace hashes with :id, :name, :role
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
