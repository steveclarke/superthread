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
          # api_key: st_xxxxxxxxxxxx

          # Default workspace ID (optional)
          # workspace: ws_abc123

          # Output format: json or table
          format: json

          # Workspace aliases for quick switching
          # workspaces:
          #   personal: ws_abc123
          #   work: ws_def456
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
        puts "Current settings:"
        puts "  api_key: #{config.api_key ? "#{config.api_key[0..10]}..." : "(not set)"}"
        puts "  base_url: #{config.base_url}"
        puts "  workspace: #{config.workspace || "(not set)"}"
        puts "  format: #{config.format}"
        puts "  workspaces: #{config.workspaces.keys.join(", ")}" unless config.workspaces.empty?
      end
    end
  end
end
