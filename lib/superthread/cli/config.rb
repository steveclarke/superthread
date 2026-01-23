# frozen_string_literal: true

require "fileutils"

module Superthread
  module Cli
    class Config < Base
      desc "init", "Create config file at ~/.config/superthread/config.yaml"
      def init
        config_path = Superthread::Configuration.new.config_path
        config_dir = File.dirname(config_path)

        if File.exist?(config_path)
          say_warning "Config file already exists at #{config_path}"
          return
        end

        FileUtils.mkdir_p(config_dir)

        File.write(config_path, <<~YAML)
          # Superthread CLI Configuration
          # See: https://github.com/steveclarke/superthread

          # API key (required) - get from Superthread settings
          # api_key: stp_xxxxxxxxxxxx

          # Output format: json or table
          format: json

          # Workspace aliases for quick switching
          # workspaces:
          #   personal: ws_abc123
          #   work: ws_def456

          # Note: Current workspace is stored in state file, not here.
          # Use 'st workspaces use <ID>' to set the default workspace.
        YAML

        say_success "Created config file at #{config_path}"
        say_info "Edit the file to add your API key and workspace settings"
      end

      desc "path", "Show config file path"
      def path
        puts Superthread::Configuration.new.config_path
      end

      desc "show", "Show current configuration (API key redacted)"
      def show
        config = Superthread::Configuration.new

        puts "Config file: #{config.config_path}"
        puts "  exists: #{File.exist?(config.config_path)}"
        puts ""
        puts "State file: #{config.state_path}"
        puts "  exists: #{File.exist?(config.state_path)}"
        puts ""
        puts "Current settings:"
        puts "  api_key: #{config.api_key ? "#{config.api_key[0..10]}..." : "(not set)"}"
        puts "  base_url: #{config.base_url}"
        puts "  workspace: #{config.workspace || "(not set)"}"
        puts "  format: #{config.format}"
        puts "  workspaces: #{config.workspaces.keys.join(", ")}" unless config.workspaces.empty?
      end

      desc "set KEY VALUE", "Set a configuration value"
      long_desc <<~DESC
        Set a configuration value in the config file.

        Supported keys:
          format    - Output format: json or table
          api_key   - Your Superthread API key
          base_url  - API base URL (advanced)

        Examples:
          st config set format json
          st config set format table
          st config set api_key stp_xxxxxxxxxxxx
      DESC
      def set(key, value)
        config = Superthread::Configuration.new
        config_path = config.config_path

        unless %w[format api_key base_url].include?(key)
          raise Thor::Error, "Unknown config key: #{key}. Valid keys: format, api_key, base_url"
        end

        if key == "format" && !%w[json table].include?(value)
          raise Thor::Error, "Invalid format: #{value}. Valid values: json, table"
        end

        # Load existing config or create empty
        existing = if File.exist?(config_path)
          YAML.safe_load_file(config_path) || {}
        else
          FileUtils.mkdir_p(File.dirname(config_path))
          {}
        end

        existing[key] = value
        File.write(config_path, YAML.dump(existing))

        say_success "Set #{key} = #{(key == "api_key") ? "#{value[0..10]}..." : value}"
      end
    end
  end
end
