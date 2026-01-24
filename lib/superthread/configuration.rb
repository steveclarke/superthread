# frozen_string_literal: true

require "fileutils"
require "yaml"

module Superthread
  class Configuration
    DEFAULT_BASE_URL = "https://api.superthread.com/v1"

    attr_accessor :base_url, :format, :timeout, :open_timeout

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

    # ========================================
    # File paths
    # ========================================

    def config_path
      @config_path ||= File.join(
        ENV.fetch("XDG_CONFIG_HOME", File.expand_path("~/.config")),
        "superthread",
        "config.yaml"
      )
    end

    def state_path
      @state_path ||= File.join(
        ENV.fetch("XDG_STATE_HOME", File.expand_path("~/.local/state")),
        "superthread",
        "context.yaml"
      )
    end

    # ========================================
    # Account management
    # ========================================

    # All accounts from config file
    def accounts
      @config_data[:accounts] || {}
    end

    # Current account name from state file
    def current_account
      @env_account || @state_data[:current_account]
    end

    # Switch to a different account (updates state)
    def current_account=(name)
      name = name.to_s
      raise ConfigurationError, "Account '#{name}' not found" unless accounts.key?(name.to_sym)

      @state_data[:current_account] = name
      save_state_file
    end

    # Get ephemeral state for an account
    def account_state(name = current_account)
      return nil unless name

      state_accounts = @state_data[:accounts] || {}
      state_accounts[name.to_sym] || {}
    end

    # Add a new account to config
    def add_account(name, api_key:)
      name = name.to_s
      @config_data[:accounts] ||= {}
      @config_data[:accounts][name.to_sym] = {api_key: api_key}
      save_config_file
    end

    # Remove an account from config and state
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

    # Save ephemeral state for an account (workspace, etc.)
    def save_account_state(name, workspace_id:, workspace_name: nil)
      name = name.to_s
      @state_data[:accounts] ||= {}
      @state_data[:accounts][name.to_sym] = {
        workspace_id: workspace_id,
        workspace_name: workspace_name
      }.compact
      save_state_file
    end

    # Set current account in state
    def set_current_account(name)
      @state_data[:current_account] = name.to_s
      save_state_file
    end

    # ========================================
    # Current context (delegates to current account)
    # ========================================

    # API key for current account
    def api_key
      return @manual_api_key if @manual_api_key
      return @env_api_key if @env_api_key

      account = accounts[current_account&.to_sym]
      account&.dig(:api_key)
    end

    # Allow manual API key override (for testing/scripting)
    def api_key=(key)
      @manual_api_key = key
    end

    # Workspace ID for current account
    def workspace
      return @env_workspace if @env_workspace

      account_state&.dig(:workspace_id)
    end

    # Workspace name for current account (for display)
    def workspace_name
      account_state&.dig(:workspace_name)
    end

    # ========================================
    # Validation
    # ========================================

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

    # Check if any accounts are configured
    def accounts?
      accounts.any?
    end

    # ========================================
    # Persistence
    # ========================================

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

    def load_state_file
      return unless File.exist?(state_path)

      state = YAML.safe_load_file(state_path, symbolize_names: true)
      return unless state.is_a?(Hash)

      @state_data = state
    rescue Psych::SyntaxError => e
      raise ConfigurationError, "Invalid YAML in #{state_path}: #{e.message}"
    end

    def load_env_vars
      @env_api_key = ENV["SUPERTHREAD_API_KEY"] if ENV["SUPERTHREAD_API_KEY"]
      @env_workspace = ENV["SUPERTHREAD_WORKSPACE_ID"] if ENV["SUPERTHREAD_WORKSPACE_ID"]
      @env_account = ENV["SUPERTHREAD_ACCOUNT"] if ENV["SUPERTHREAD_ACCOUNT"]
      @base_url = ENV["SUPERTHREAD_API_BASE_URL"] if ENV["SUPERTHREAD_API_BASE_URL"]
    end

    # Convert symbol keys to strings for YAML output
    def stringify_keys(hash)
      return {} unless hash

      hash.transform_keys(&:to_s).transform_values do |v|
        v.is_a?(Hash) ? stringify_keys(v) : v
      end
    end
  end
end
