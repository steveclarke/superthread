# frozen_string_literal: true

require "fileutils"

module Superthread
  module Cli
    # Interactive setup wizard for first-time configuration.
    module Setup
      module_function

      def execute
        Ui.header "Superthread CLI Setup"
        Ui.blank

        config = Superthread::Configuration.new

        # Step 1: Determine if adding new or reconfiguring
        account_name = prompt_account_name(config)
        return unless account_name

        # Step 2: API Key
        Ui.blank
        api_key = prompt_api_key
        return unless api_key

        # Step 3: Validate and fetch workspaces
        Ui.blank
        workspaces = fetch_workspaces(api_key)
        return unless workspaces

        # Step 4: Select workspace (auto-selects if only one)
        Ui.blank
        workspace = select_workspace(workspaces)
        return unless workspace

        # Step 5: Save configuration
        Ui.blank
        save_account(config, account_name, api_key, workspace)

        # Done!
        Ui.blank
        Ui.success "Setup complete!"
        Ui.blank
        Ui.muted "Account '#{account_name}' is now active."
        Ui.blank
        Ui.muted "Try: suth spaces list"
        Ui.muted "     suth boards list --space SPACE_ID"
        Ui.muted "     suth cards list --board BOARD_ID"
        Ui.blank
        Ui.muted "To add another account: suth account add <name>"
        Ui.muted "To switch accounts:     suth account use <name>"
      end

      def prompt_account_name(config)
        Ui.section "Step 1: Account"

        existing = config.accounts.keys.map(&:to_s)

        # No existing accounts - first time setup
        if existing.empty?
          return prompt_new_account_name("personal")
        end

        # Show existing accounts
        current = config.current_account
        Ui.muted "Existing accounts: #{existing.map { |a| (a == current) ? "#{a} (current)" : a }.join(", ")}"
        Ui.blank

        # Let user choose what to do
        choice = Ui.choose(
          ["Add new account", "Reconfigure existing account"],
          header: "What would you like to do?"
        )
        return nil if choice.nil?

        Ui.blank

        if choice.start_with?("Add")
          # Suggest a name that doesn't exist
          suggestion = %w[personal work].find { |n| !existing.include?(n) }
          prompt_new_account_name(suggestion)
        else
          prompt_existing_account(existing)
        end
      end

      def prompt_new_account_name(suggestion)
        prompt = if suggestion
          "Account name (default: #{suggestion}):"
        else
          "Account name:"
        end

        input = Ui.input(prompt)
        name = input&.strip
        name = suggestion if name.nil? || name.empty?

        if name.nil? || name.empty?
          Ui.error "Account name is required"
          return nil
        end

        name
      end

      def prompt_existing_account(existing)
        if existing.length == 1
          name = existing.first
          Ui.info "Reconfiguring account: #{name}"
          return name
        end

        choice = Ui.choose(existing, header: "Select account to reconfigure:")
        return nil if choice.nil?

        choice
      end

      def prompt_api_key
        Ui.section "Step 2: API Key"
        Ui.muted "Get your API key from Superthread Settings > API"
        Ui.blank

        api_key = Ui.password("Enter your API key:")

        if api_key.nil? || api_key.strip.empty?
          Ui.error "API key is required"
          return nil
        end

        api_key.strip
      end

      def fetch_workspaces(api_key)
        Ui.section "Step 3: Connecting..."

        workspaces = Ui.spin("Fetching workspaces...") do
          temp_client = Superthread::Client.new(api_key: api_key)
          user = temp_client.users.me
          extract_teams(user)
        end

        if workspaces.empty?
          Ui.error "No workspaces found for this API key"
          return nil
        end

        Ui.success "Found #{workspaces.length} workspace(s)"
        workspaces
      rescue Superthread::AuthenticationError
        Ui.error "Invalid API key"
        nil
      rescue Superthread::ApiError => e
        Ui.error "API error: #{e.message}"
        nil
      end

      def select_workspace(workspaces)
        Ui.section "Step 4: Select Workspace"
        Ui.blank

        if workspaces.length == 1
          ws = workspaces.first
          Ui.info "Using workspace: #{ws[:name]}"
          return ws
        end

        choices = workspaces.map { |ws| "#{ws[:name]} (#{ws[:id]})" }
        selected = Ui.choose(choices, header: "Select your default workspace:")

        return nil if selected.nil?

        # Find the selected workspace
        workspaces.find { |ws| selected.include?(ws[:id]) }
      end

      def save_account(config, account_name, api_key, workspace)
        Ui.section "Step 5: Saving Configuration"

        # Add/update account with API key in config file
        config.add_account(account_name, api_key: api_key)
        Ui.muted "Saved account '#{account_name}' to #{config.config_path}"

        # Save workspace to account state
        config.save_account_state(account_name,
          workspace_id: workspace[:id],
          workspace_name: workspace[:name])
        Ui.muted "Saved workspace to #{config.state_path}"

        # Set as current account
        config.current_account = account_name
        Ui.muted "Set '#{account_name}' as current account"
      end

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
