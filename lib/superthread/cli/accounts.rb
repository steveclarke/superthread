# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing Superthread accounts.
    #
    # Accounts store API credentials and workspace associations. Multiple
    # accounts can be configured and switched between using these commands.
    class Accounts < Base
      desc "list", "List all configured accounts"
      # Lists all configured accounts with their workspace associations.
      #
      # @return [void]
      def list
        accounts = app_config.accounts

        if accounts.empty?
          Ui.warning "No accounts configured"
          Ui.muted "Run 'suth setup' to add an account"
          return
        end

        current = app_config.current_account

        Ui.section "Accounts"
        accounts.each do |name, _data|
          state = app_config.account_state(name.to_s)
          workspace_name = state&.dig(:workspace_name) || state&.dig(:workspace_id) || "(no workspace)"
          marker = (name.to_s == current) ? "*" : " "
          puts "  #{marker} #{name.to_s.ljust(15)} #{workspace_name}"
        end
        puts ""
        Ui.muted "Use 'suth account use <name>' to switch accounts"
      end

      desc "show [NAME]", "Show account details (defaults to current account)"
      # Displays details for a specific account or the current account.
      #
      # @param name [String, nil] account name to show, or nil for current account
      # @return [void]
      def show(name = nil)
        name ||= app_config.current_account

        unless name
          Ui.warning "No account selected"
          Ui.muted "Run 'suth setup' to configure an account"
          return
        end

        unless app_config.accounts.key?(name.to_sym)
          Ui.error "Account '#{name}' not found"
          Ui.muted "Available accounts: #{app_config.accounts.keys.join(", ")}"
          return
        end

        account_config = app_config.accounts[name.to_sym]
        state = app_config.account_state(name)
        is_current = name == app_config.current_account

        label = is_current ? "Account: #{name} (current)" : "Account: #{name}"
        Ui.section label
        puts "  API Key:        #{mask_api_key(account_config&.dig(:api_key))}"
        puts "  Workspace ID:   #{state&.dig(:workspace_id) || "(not set)"}"
        puts "  Workspace Name: #{state&.dig(:workspace_name) || "(not set)"}"
      end

      desc "use NAME", "Switch to a different account"
      # Switches the active account to the specified account.
      #
      # @param name [String] account name to switch to
      # @return [void]
      def use(name)
        unless app_config.accounts.key?(name.to_sym)
          Ui.error "Account '#{name}' not found"
          Ui.muted "Available accounts: #{app_config.accounts.keys.join(", ")}"
          return
        end

        app_config.current_account = name
        state = app_config.account_state(name)
        workspace_name = state&.dig(:workspace_name) || name

        output_success "Switched to account '#{name}' (#{workspace_name})"
      end

      desc "add NAME", "Add a new account"
      method_option :with_token, type: :boolean,
        desc: "Read API key from standard input (for scripts and agents)"
      method_option :workspace_name, type: :string,
        desc: "Select workspace by name (non-interactive)"
      # Adds a new account with API key and workspace selection.
      #
      # By default, prompts interactively for the API key. Use --with-token
      # to read the key from standard input instead (like gh auth login --with-token).
      #
      # @param name [String] unique name for the new account
      # @return [void]
      def add(name)
        if app_config.accounts.key?(name.to_sym)
          Ui.error "Account '#{name}' already exists"
          Ui.muted "Use 'suth account remove #{name}' first to replace it"
          return
        end

        api_key = read_api_key(name)
        return unless api_key

        # Validate and fetch workspaces
        begin
          Ui.spin("Validating API key") do
            temp_client = Superthread::Client.new(api_key: api_key)
            @user = temp_client.users.me
          end
        rescue Superthread::AuthenticationError
          Ui.error "Invalid API key"
          return
        rescue Superthread::ApiError => e
          Ui.error "API error: #{e.message}"
          return
        end

        teams = @user.teams || []
        if teams.empty?
          Ui.error "No workspaces found for this API key"
          return
        end

        workspace = select_workspace(teams)
        return unless workspace

        # Save account
        app_config.add_account(name, api_key: api_key)
        app_config.save_account_state(name,
          workspace_id: workspace.id,
          workspace_name: workspace.team_name)
        app_config.set_current_account(name)

        output_success "Account '#{name}' configured (#{workspace.team_name || workspace.id})"
      end

      desc "remove NAME", "Remove an account"
      # Removes a configured account after confirmation.
      #
      # @param name [String] account name to remove
      # @return [void]
      def remove(name)
        unless app_config.accounts.key?(name.to_sym)
          Ui.error "Account '#{name}' not found"
          return
        end

        confirming("Remove account '#{name}'?") do
          app_config.remove_account(name)
          output_success "Account '#{name}' removed"

          if app_config.accounts.empty?
            Ui.muted "No accounts remaining. Run 'suth setup' to add one."
          elsif app_config.current_account.nil?
            first_account = app_config.accounts.keys.first
            Ui.muted "Tip: Run 'suth account use #{first_account}' to select an account"
          end
        end
      end

      private

      # Reads the API key from stdin (--with-token) or interactive prompt.
      #
      # @param account_name [String] the account name (used in interactive prompt)
      # @return [String, nil] the API key, or nil if empty/missing
      def read_api_key(account_name)
        api_key = if options[:with_token]
          $stdin.gets&.chomp
        else
          Ui.password("API key for '#{account_name}'")
        end

        if api_key.nil? || api_key.empty?
          if options[:with_token]
            Ui.error "No API key provided on standard input"
            Ui.muted "Usage: echo $SUPERTHREAD_API_KEY | suth accounts add NAME --with-token"
          else
            Ui.error "API key is required"
          end
          return nil
        end

        api_key
      end

      # Selects a workspace from the list of teams.
      #
      # Uses --workspace-name if provided, auto-selects if only one,
      # or prompts interactively.
      #
      # @param teams [Array] available workspaces
      # @return [Object, nil] the selected workspace, or nil on error
      def select_workspace(teams)
        if teams.length == 1
          return teams.first
        end

        if options[:workspace_name]
          match = teams.find { |t| t.team_name&.downcase == options[:workspace_name].downcase }
          unless match
            names = teams.map { |t| t.team_name || t.id }.join(", ")
            Ui.error "Workspace '#{options[:workspace_name]}' not found"
            Ui.muted "Available: #{names}"
            return nil
          end
          return match
        end

        if options[:with_token]
          Ui.muted "Multiple workspaces found, using '#{teams.first.team_name || teams.first.id}'"
          Ui.muted "Use --workspace-name to select a different workspace"
          return teams.first
        end

        Ui.muted "Found #{teams.length} workspaces:"
        teams.each_with_index do |team, i|
          puts "  #{i + 1}. #{team.team_name || team.id}"
        end
        choice = Ui.input("Select workspace (1-#{teams.length})")&.to_i || 1
        teams[choice - 1] || teams.first
      end

      # Masks an API key for display, showing only the first 4 and last 4 characters.
      #
      # @param key [String, nil] the API key to mask
      # @return [String] the masked key or "(not set)" if nil
      def mask_api_key(key)
        return "(not set)" unless key
        return "***" if key.length < 10

        "#{key[0..3]}...#{key[-4..]}"
      end
    end
  end
end
