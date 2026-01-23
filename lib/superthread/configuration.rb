# frozen_string_literal: true

require "fileutils"
require "yaml"

module Superthread
  class Configuration
    DEFAULT_BASE_URL = "https://api.superthread.com/v1"

    attr_accessor :api_key, :base_url, :workspace, :format, :workspaces,
      :timeout, :open_timeout

    def initialize
      @base_url = DEFAULT_BASE_URL
      @format = "table"
      @workspaces = {}
      @timeout = 30
      @open_timeout = 10

      load_config_file
      load_state_file
      load_env_vars
    end

    # Config file for persistent preferences (API key, base URL, etc.)
    def config_path
      @config_path ||= File.join(
        ENV.fetch("XDG_CONFIG_HOME", File.expand_path("~/.config")),
        "superthread",
        "config.yaml"
      )
    end

    # State file for ephemeral context (current workspace)
    def state_path
      @state_path ||= File.join(
        ENV.fetch("XDG_STATE_HOME", File.expand_path("~/.local/state")),
        "superthread",
        "context.yaml"
      )
    end

    def validate!
      return if api_key && !api_key.empty?

      raise Superthread::ConfigurationError,
        "API key is required. Set SUPERTHREAD_API_KEY environment variable " \
        "or add api_key to #{config_path}"
    end

    # Resolve workspace ID from alias or direct ID
    def resolve_workspace(workspace_ref)
      return nil if workspace_ref.nil?

      workspaces[workspace_ref.to_sym] || workspace_ref
    end

    # Save workspace ID to state file (not config)
    def save_workspace(workspace_id)
      state = load_existing_state
      state["workspace"] = workspace_id

      FileUtils.mkdir_p(File.dirname(state_path))
      File.write(state_path, YAML.dump(state))

      @workspace = workspace_id
    end

    # Clear current workspace from state
    def clear_workspace
      state = load_existing_state
      state.delete("workspace")

      if state.empty?
        FileUtils.rm_f(state_path)
      else
        File.write(state_path, YAML.dump(state))
      end

      @workspace = nil
    end

    private

    def load_existing_config
      return {} unless File.exist?(config_path)

      YAML.safe_load_file(config_path) || {}
    rescue Psych::SyntaxError
      {}
    end

    def load_existing_state
      return {} unless File.exist?(state_path)

      YAML.safe_load_file(state_path) || {}
    rescue Psych::SyntaxError
      {}
    end

    # Load persistent preferences from config file
    def load_config_file
      return unless File.exist?(config_path)

      config = YAML.safe_load_file(config_path, symbolize_names: true)
      return unless config.is_a?(Hash)

      @api_key ||= config[:api_key]
      @base_url = config[:base_url] if config[:base_url]
      @format = config[:format] if config[:format]
      @workspaces = config[:workspaces] || {}
      @timeout = config[:timeout] if config[:timeout]
      @open_timeout = config[:open_timeout] if config[:open_timeout]

      # Legacy: migrate workspace from config to state if present
      if config[:workspace] && !File.exist?(state_path)
        @workspace = config[:workspace]
      end
    rescue Psych::SyntaxError => e
      raise Superthread::ConfigurationError, "Invalid YAML in #{config_path}: #{e.message}"
    end

    # Load ephemeral context from state file
    def load_state_file
      return unless File.exist?(state_path)

      state = YAML.safe_load_file(state_path, symbolize_names: true)
      return unless state.is_a?(Hash)

      @workspace = state[:workspace] if state[:workspace]
    rescue Psych::SyntaxError => e
      raise Superthread::ConfigurationError, "Invalid YAML in #{state_path}: #{e.message}"
    end

    def load_env_vars
      @api_key = ENV["SUPERTHREAD_API_KEY"] if ENV["SUPERTHREAD_API_KEY"]
      @base_url = ENV["SUPERTHREAD_API_BASE_URL"] if ENV["SUPERTHREAD_API_BASE_URL"]
      @workspace = ENV["SUPERTHREAD_WORKSPACE_ID"] if ENV["SUPERTHREAD_WORKSPACE_ID"]
    end
  end
end
