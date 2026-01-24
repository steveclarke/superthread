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

        # Step 1: API Key
        api_key = prompt_api_key
        return unless api_key

        # Step 2: Validate and fetch workspaces
        Ui.blank
        workspaces = fetch_workspaces(api_key)
        return unless workspaces

        # Step 3: Select workspace
        Ui.blank
        workspace_id = prompt_workspace(workspaces)
        return unless workspace_id

        # Step 4: Save configuration
        Ui.blank
        save_configuration(api_key, workspace_id)

        # Done!
        Ui.blank
        Ui.success "Setup complete!"
        Ui.blank
        Ui.muted "Try: suth spaces list"
        Ui.muted "     suth boards list --space SPACE_ID"
        Ui.muted "     suth cards list --board BOARD_ID"
      end

      def prompt_api_key
        Ui.section "Step 1: API Key"
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
        Ui.section "Step 2: Connecting..."

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

      def prompt_workspace(workspaces)
        Ui.section "Step 3: Select Workspace"
        Ui.blank

        if workspaces.length == 1
          ws = workspaces.first
          Ui.info "Using workspace: #{ws[:name]}"
          return ws[:id]
        end

        choices = workspaces.map { |ws| "#{ws[:name]} (#{ws[:id]})" }
        selected = Ui.choose(choices, header: "Select your default workspace:")

        return nil if selected.nil?

        # Extract ID from selection
        workspaces.find { |ws| selected.include?(ws[:id]) }&.dig(:id)
      end

      def save_configuration(api_key, workspace_id)
        Ui.section "Step 4: Saving Configuration"

        config = Superthread::Configuration.new
        config_path = config.config_path
        config_dir = File.dirname(config_path)

        # Create config directory
        FileUtils.mkdir_p(config_dir)

        # Save API key to config file
        config_data = if File.exist?(config_path)
          YAML.safe_load_file(config_path) || {}
        else
          {}
        end

        config_data["api_key"] = api_key
        config_data["format"] ||= "table"
        File.write(config_path, YAML.dump(config_data))
        Ui.muted "Saved API key to #{config_path}"

        # Save workspace to state file
        config.save_workspace(workspace_id)
        Ui.muted "Saved workspace to #{config.state_path}"
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
