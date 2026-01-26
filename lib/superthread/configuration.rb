# frozen_string_literal: true

require "fileutils"
require "yaml"

module Superthread
  # Manages configuration and state for the Superthread CLI.
  #
  # Handles multi-account management, API credentials, and persistent state.
  # Configuration is stored in XDG-compliant locations:
  # - Config: ~/.config/superthread/config.yaml (accounts, settings)
  # - State: ~/.local/state/superthread/context.yaml (current account, workspace)
  #
  # Environment variables can override file-based configuration:
  # - SUPERTHREAD_API_KEY - API key for authentication
  # - SUPERTHREAD_WORKSPACE_ID - Default workspace ID
  # - SUPERTHREAD_ACCOUNT - Account name to use
  # - SUPERTHREAD_API_BASE_URL - Custom API base URL
  #
  # @example Basic usage
  #   config = Superthread::Configuration.new
  #   config.validate!
  #   config.api_key  # => "sk_..."
  class Configuration
    # Default API base URL for the Superthread API.
    DEFAULT_BASE_URL = "https://api.superthread.com/v1"

    # @return [String] API base URL
    attr_accessor :base_url

    # @return [String] Output format for CLI (table, json, etc.)
    attr_accessor :format

    # @return [Integer] HTTP request timeout in seconds
    attr_accessor :timeout

    # @return [Integer] HTTP connection timeout in seconds
    attr_accessor :open_timeout

    # Creates a new Configuration instance.
    #
    # Loads configuration from files and environment variables in this order:
    # 1. Default values
    # 2. Config file (~/.config/superthread/config.yaml)
    # 3. State file (~/.local/state/superthread/context.yaml)
    # 4. Environment variables (highest priority)
    def initialize
      @base_url = DEFAULT_BASE_URL
      @format = "table"
      @timeout = 30
      @open_timeout = 10
      @config_data = {}
      @state_data = {}

      load_config_file
      load_state_file
      load_env_vars
    end

    # Returns the path to the configuration file.
    #
    # Uses XDG_CONFIG_HOME if set, otherwise defaults to ~/.config.
    #
    # @return [String] absolute path to config.yaml
    def config_path
      @config_path ||= File.join(
        ENV.fetch("XDG_CONFIG_HOME", File.expand_path("~/.config")),
        "superthread",
        "config.yaml"
      )
    end

    # Returns the path to the state file.
    #
    # Uses XDG_STATE_HOME if set, otherwise defaults to ~/.local/state.
    # State includes ephemeral data like current account and workspace.
    #
    # @return [String] absolute path to context.yaml
    def state_path
      @state_path ||= File.join(
        ENV.fetch("XDG_STATE_HOME", File.expand_path("~/.local/state")),
        "superthread",
        "context.yaml"
      )
    end

    # Returns all configured accounts from the config file.
    #
    # @return [Hash{Symbol => Hash}] account names mapped to their settings
    def accounts
      @config_data[:accounts] || {}
    end

    # Returns the current account name.
    #
    # Checks environment variable first, then falls back to state file.
    #
    # @return [String, nil] current account name or nil if not set
    def current_account
      @env_account || @state_data[:current_account]
    end

    # Switches to a different account.
    #
    # Updates the state file with the new current account.
    #
    # @param name [String] account name to switch to
    # @raise [ConfigurationError] if the account does not exist
    def current_account=(name)
      name = name.to_s
      raise ConfigurationError, "Account '#{name}' not found" unless accounts.key?(name.to_sym)

      @state_data[:current_account] = name
      save_state_file
    end

    # Returns ephemeral state for an account.
    #
    # State includes workspace_id and workspace_name.
    #
    # @param name [String, nil] account name (defaults to current account)
    # @return [Hash, nil] account state hash or nil if not found
    def account_state(name = current_account)
      return nil unless name

      state_accounts = @state_data[:accounts] || {}
      state_accounts[name.to_sym] || {}
    end

    # Adds a new account to the configuration.
    #
    # @param name [String] unique account name
    # @param api_key [String] API key for authentication
    def add_account(name, api_key:)
      name = name.to_s
      @config_data[:accounts] ||= {}
      @config_data[:accounts][name.to_sym] = {api_key: api_key}
      save_config_file
    end

    # Removes an account from config and state.
    #
    # If removing the current account, clears the current account selection.
    #
    # @param name [String] account name to remove
    def remove_account(name)
      name = name.to_s
      @config_data[:accounts]&.delete(name.to_sym)
      @state_data[:accounts]&.delete(name.to_sym)

      # If removing current account, clear it
      if @state_data[:current_account] == name
        @state_data.delete(:current_account)
      end

      save_config_file
      save_state_file
    end

    # Saves ephemeral state for an account.
    #
    # Used to persist workspace selection between sessions.
    #
    # @param name [String] the configured account alias (e.g., "work", "personal")
    # @param workspace_id [String] workspace ID to save
    # @param workspace_name [String, nil] optional workspace name for display
    def save_account_state(name, workspace_id:, workspace_name: nil)
      name = name.to_s
      @state_data[:accounts] ||= {}
      @state_data[:accounts][name.to_sym] = {
        workspace_id: workspace_id,
        workspace_name: workspace_name
      }.compact
      save_state_file
    end

    # Sets the current account in state.
    #
    # Unlike the setter, this does not validate the account exists.
    #
    # @param name [String] the configured account alias to make current
    def set_current_account(name)
      @state_data[:current_account] = name.to_s
      save_state_file
    end

    # Returns the API key for the current context.
    #
    # Checks in order: manual override, environment variable, account config.
    #
    # @return [String, nil] API key or nil if not configured
    def api_key
      return @manual_api_key if @manual_api_key
      return @env_api_key if @env_api_key

      account = accounts[current_account&.to_sym]
      account&.dig(:api_key)
    end

    # Sets a manual API key override.
    #
    # Useful for testing or scripting without modifying config files.
    #
    # @param key [String] Superthread API key for authentication
    def api_key=(key)
      @manual_api_key = key
    end

    # Returns the workspace ID for the current context.
    #
    # Checks environment variable first, then account state.
    #
    # @return [String, nil] workspace ID or nil if not set
    def workspace
      return @env_workspace if @env_workspace

      account_state&.dig(:workspace_id)
    end

    # Returns the workspace name for display purposes.
    #
    # @return [String, nil] workspace name or nil if not set
    def workspace_name
      account_state&.dig(:workspace_name)
    end

    # Validates that required configuration is present.
    #
    # @return [void]
    # @raise [ConfigurationError] if no account is configured
    # @raise [ConfigurationError] if API key is missing
    def validate!
      # Allow manual or env API key to bypass account requirement
      return if @manual_api_key && !@manual_api_key.empty?
      return if @env_api_key && !@env_api_key.empty?

      unless current_account
        raise ConfigurationError,
          "No account configured. Run 'suth setup' to configure an account."
      end

      unless api_key && !api_key.empty?
        raise ConfigurationError,
          "API key not found for account '#{current_account}'. " \
          "Run 'suth setup' or set SUPERTHREAD_API_KEY environment variable."
      end
    end

    # Checks if any accounts are configured.
    #
    # @return [Boolean] true if at least one account exists
    def accounts?
      accounts.any?
    end

    # Persists the current configuration to the config file.
    #
    # Creates parent directories if they don't exist.
    #
    # @return [void]
    def save_config_file
      FileUtils.mkdir_p(File.dirname(config_path))
      data = {
        "accounts" => stringify_keys(accounts),
        "format" => @format,
        "timeout" => @timeout,
        "open_timeout" => @open_timeout
      }
      data["base_url"] = @base_url if @base_url != DEFAULT_BASE_URL
      File.write(config_path, YAML.dump(data))
    end

    # Persists the current state to the state file.
    #
    # Creates parent directories if they don't exist.
    #
    # @return [void]
    def save_state_file
      FileUtils.mkdir_p(File.dirname(state_path))
      data = {}
      data["current_account"] = @state_data[:current_account] if @state_data[:current_account]
      if @state_data[:accounts]&.any?
        data["accounts"] = stringify_keys(@state_data[:accounts])
      end
      File.write(state_path, YAML.dump(data))
    end

    private

    # Loads configuration from the config file.
    #
    # @return [void]
    def load_config_file
      return unless File.exist?(config_path)

      config = YAML.safe_load_file(config_path, symbolize_names: true)
      return unless config.is_a?(Hash)

      @config_data = config
      @base_url = config[:base_url] if config[:base_url]
      @format = config[:format] if config[:format]
      @timeout = config[:timeout] if config[:timeout]
      @open_timeout = config[:open_timeout] if config[:open_timeout]
    rescue Psych::SyntaxError => e
      raise ConfigurationError, "Invalid YAML in #{config_path}: #{e.message}"
    end

    # Loads state from the state file.
    #
    # @return [void]
    def load_state_file
      return unless File.exist?(state_path)

      state = YAML.safe_load_file(state_path, symbolize_names: true)
      return unless state.is_a?(Hash)

      @state_data = state
    rescue Psych::SyntaxError => e
      raise ConfigurationError, "Invalid YAML in #{state_path}: #{e.message}"
    end

    # Loads configuration overrides from environment variables.
    #
    # @return [void]
    def load_env_vars
      @env_api_key = ENV["SUPERTHREAD_API_KEY"] if ENV["SUPERTHREAD_API_KEY"]
      @env_workspace = ENV["SUPERTHREAD_WORKSPACE_ID"] if ENV["SUPERTHREAD_WORKSPACE_ID"]
      @env_account = ENV["SUPERTHREAD_ACCOUNT"] if ENV["SUPERTHREAD_ACCOUNT"]
      @base_url = ENV["SUPERTHREAD_API_BASE_URL"] if ENV["SUPERTHREAD_API_BASE_URL"]
    end

    # Converts symbol keys to strings for YAML output.
    #
    # @param hash [Hash, nil] the hash to convert
    # @return [Hash] the hash with string keys
    def stringify_keys(hash)
      return {} unless hash

      hash.transform_keys(&:to_s).transform_values do |v|
        v.is_a?(Hash) ? stringify_keys(v) : v
      end
    end
  end
end
