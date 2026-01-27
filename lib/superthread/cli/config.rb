# frozen_string_literal: true

require "fileutils"

module Superthread
  module Cli
    # CLI commands for managing Superthread configuration files.
    # Handles config file creation, viewing settings, and updating values.
    class Config < Base
      desc "init", "Create config file at ~/.config/superthread/config.yaml"
      # Creates the Superthread configuration file with default settings.
      #
      # @return [void]
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

          # Accounts are configured via 'suth setup' or 'suth account add'
          # accounts:
          #   personal:
          #     api_key: stp_xxxxxxxxxxxx
          #   work:
          #     api_key: stp_yyyyyyyyyyyy

          # Output format: json or table
          format: table
        YAML

        say_success "Created config file at #{config_path}"
        say_info "Run 'suth setup' to configure your account"
      end

      desc "path", "Show config file path"
      # Displays the path to the configuration file.
      #
      # @return [void]
      def path
        puts Superthread::Configuration.new.config_path
      end

      desc "show", "Show current configuration"
      # Displays the current configuration settings and account information.
      #
      # @return [void]
      def show
        cfg = Superthread::Configuration.new

        puts "Config file: #{cfg.config_path}"
        puts "  exists: #{File.exist?(cfg.config_path)}"
        puts ""
        puts "State file: #{cfg.state_path}"
        puts "  exists: #{File.exist?(cfg.state_path)}"
        puts ""
        puts "Current settings:"
        puts "  current_account: #{cfg.current_account || "(not set)"}"
        puts "  api_key: #{cfg.api_key ? "#{cfg.api_key[0..6]}..." : "(not set)"}"
        puts "  workspace: #{cfg.workspace || "(not set)"}"
        puts "  format: #{cfg.format}"
        puts ""

        if cfg.accounts.any?
          puts "Accounts:"
          cfg.accounts.each do |name, _data|
            state = cfg.account_state(name.to_s)
            workspace = state&.dig(:workspace_name) || state&.dig(:workspace_id) || "(no workspace)"
            marker = (name.to_s == cfg.current_account) ? "*" : " "
            puts "  #{marker} #{name}: #{workspace}"
          end
        else
          puts "Accounts: (none configured)"
          puts "  Run 'suth setup' to add an account"
        end
      end

      desc "set KEY VALUE", "Set a configuration value"
      long_desc <<~DESC
        Set a configuration value in the config file.

        Supported keys:
          format    - Output format: json or table
          base_url  - API base URL (advanced)

        Note: API keys are managed per-account. Use 'suth account add' to configure accounts.

        Examples:
          suth config set format json
          suth config set format table
      DESC
      # Sets a configuration value in the config file.
      #
      # @param key [String] configuration key to set (format or base_url)
      # @param value [String] value to assign to the configuration key
      # @return [void]
      def set(key, value)
        cfg = Superthread::Configuration.new

        unless %w[format base_url].include?(key)
          raise Thor::Error, "Unknown config key: #{key}. Valid keys: format, base_url"
        end

        if key == "format" && !%w[json table].include?(value)
          raise Thor::Error, "Invalid format: #{value}. Valid values: json, table"
        end

        case key
        when "format"
          cfg.format = value
        when "base_url"
          cfg.base_url = value
        end

        cfg.save_config_file

        say_success "Set #{key} = #{value}"
      end
    end
  end
end
