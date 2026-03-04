# frozen_string_literal: true

require "thor"
require "json"

module Superthread
  module Cli
    # Base class for all CLI commands.
    # Provides common options, client access, and output formatting.
    class Base < Thor
      # Indicates Thor should exit with failure code on errors.
      #
      # @return [Boolean] always returns true
      def self.exit_on_failure?
        true
      end

      class_option :verbose, type: :boolean, aliases: "-v", desc: "Detailed logging"
      class_option :quiet, type: :boolean, aliases: "-q", desc: "Minimal logging"
      class_option :workspace, type: :string, aliases: "-w", desc: "Workspace (ID or name)"
      class_option :json, type: :boolean, desc: "Output as JSON"
      class_option :account, type: :string, aliases: "-a", desc: "Use specific account"
      class_option :skip_confirm, type: :boolean, aliases: ["-y", "--yes"], desc: "Auto-confirm prompts"
      class_option :limit, type: :numeric, desc: "Max items to show (default: 50)"

      include Concerns::WorkspaceResolvable
      include Concerns::SpaceResolvable
      include Concerns::BoardResolvable
      include Concerns::SprintResolvable
      include Concerns::UserResolvable
      include Concerns::TagResolvable
      include Concerns::ListResolvable

      private

      # Get the Superthread API client, creating if needed.
      #
      # @return [Superthread::Client] the configured API client
      def client
        @client ||= if options[:account]
          # Create client with specific account's API key
          cfg = config_for_account(options[:account])
          Superthread::Client.new(api_key: cfg.api_key)
        else
          Superthread::Client.new
        end
      end

      # Get configuration for a specific account (for --account flag).
      #
      # @param account_name [String] the account name from config file
      # @return [Superthread::Configuration] configured for the specified account
      # @raise [Thor::Error] if the account is not found
      def config_for_account(account_name)
        cfg = Superthread::Configuration.new
        account_data = cfg.accounts[account_name]

        unless account_data
          raise Thor::Error, "Account '#{account_name}' not found. " \
            "Use 'suth account list' to see configured accounts."
        end

        # Create a new config with this account as current
        cfg.current_account = account_name
        cfg
      end

      # Check if a value looks like a resource ID (alphanumeric, reasonable length).
      #
      # @param value [String] the value to check
      # @return [Boolean] true if it matches ID pattern
      def looks_like_id?(value)
        # IDs are short alphanumeric strings or full UUIDs (36 chars with hyphens)
        value.match?(/\A[a-zA-Z0-9_-]+\z/) && value.length <= 36
      end

      # Validate that --space is provided when --sprint is used.
      #
      # @return [void]
      # @raise [Thor::Error] if --sprint is set without --space
      def require_space_for_sprint!
        return unless options[:sprint] && !options[:space]

        raise Thor::Error, "--space is required when using --sprint"
      end

      # Check if color output is enabled based on TTY and quiet mode.
      #
      # @return [Boolean] true if colors should be applied to output
      def color_enabled?
        $stdout.tty? && !options[:quiet]
      end

      # Check if JSON output is enabled via --json flag or config setting.
      #
      # @return [Boolean] true if output should be JSON formatted
      def json_output?
        options[:json] || app_config.format == "json"
      end

      # Get the application configuration object.
      #
      # Named app_config to avoid collision with Thor's subcommand delegation
      # (Thor generates a `config` method for the `config` subcommand).
      #
      # @return [Superthread::Configuration] the configuration instance
      def app_config
        @app_config ||= Superthread::Configuration.new
      end

      # Output a single item as detail view or JSON.
      #
      # In JSON mode, outputs as JSON object. Otherwise, outputs as key-value pairs.
      #
      # @param item [Object] the item to output (model object or hash)
      # @param fields [Array<Symbol>] the fields to display in table mode
      # @param labels [Hash{Symbol => String}] custom labels for field names
      # @return [void]
      def output_item(item, fields: nil, labels: {})
        if json_output?
          puts Formatter.json(item)
        else
          fields ||= default_detail_fields(item)
          puts Formatter.detail(item, fields: fields, labels: labels, color_enabled: color_enabled?)
        end
      end

      # Output a collection as table or JSON array.
      #
      # Applies --limit truncation (default: 50). When truncated, shows a count
      # footer in table mode or wraps with metadata in JSON mode.
      #
      # @param items [Array, Collection] the items to output
      # @param columns [Array<Symbol>] the columns to display in table mode
      # @param headers [Hash{Symbol => String}] custom labels for column headers
      # @return [void]
      def output_list(items, columns: nil, headers: {})
        all_items = items.respond_to?(:items) ? items.items : Array(items)
        limit = effective_limit
        truncated = all_items.length > limit
        visible = truncated ? all_items.first(limit) : all_items

        if json_output?
          if truncated
            puts JSON.pretty_generate(
              items: visible.map { |i| i.respond_to?(:to_h) ? i.to_h : i },
              total: all_items.length,
              truncated: true,
              limit: limit
            )
          else
            puts Formatter.json(visible)
          end
        else
          columns ||= default_list_columns(visible)
          result = Formatter.table(visible, columns: columns, headers: headers, color_enabled: color_enabled?)
          if result.empty?
            say "No items found.", :yellow unless options[:quiet]
          else
            puts result
            if truncated
              say "Showing #{limit} of #{all_items.length}. Use --limit to adjust.", :yellow
            end
          end
        end
      end

      # Output raw data with automatic format detection.
      #
      # Legacy support for commands not yet updated. In JSON mode or when data
      # is not a recognized object type, outputs as JSON.
      #
      # @param data [Object] the data to output (auto-detects format)
      # @return [void]
      def output(data)
        if json_output?
          puts Formatter.json(data)
        elsif data.respond_to?(:items)
          output_list(data)
        elsif data.is_a?(Superthread::Object)
          output_item(data)
        else
          puts Formatter.json(data)
        end
      end

      # Output a success message in green or as JSON.
      #
      # @param message [String] the success message to display
      # @return [void]
      def output_success(message)
        if json_output?
          puts Formatter.json({success: true, message: message})
        else
          say message, :green unless options[:quiet]
        end
      end

      # Get default detail fields based on the item's model type.
      #
      # @param item [Object] the item to determine fields for
      # @return [Array<Symbol>] the default fields for this item type
      def default_detail_fields(item)
        fields = item.class.detail_fields if item.class.respond_to?(:detail_fields)
        return fields if fields&.any?

        item.respond_to?(:keys) ? item.keys.take(10) : []
      end

      # Get default list columns based on the first item's model type.
      #
      # @param items [Array, Collection] the items to determine columns for
      # @return [Array<Symbol>] the default columns for this collection type
      def default_list_columns(items)
        first = items.respond_to?(:first) ? items.first : nil
        return [] if first.nil?

        columns = first.class.list_columns if first.class.respond_to?(:list_columns)
        return columns if columns&.any?

        first.respond_to?(:keys) ? first.keys.take(5) : []
      end

      # Extract specified options as a hash with symbol keys for API calls.
      #
      # @param keys [Array<Symbol>] the option keys to extract
      # @return [Hash{Symbol => Object}] hash of non-nil option values
      def symbolized_options(*keys)
        keys.each_with_object({}) do |key, hash|
          value = options[key.to_s]
          hash[key] = value unless value.nil?
        end
      end

      # Display an informational message in cyan unless quiet mode.
      #
      # @param message [String] the info message to display
      # @return [void]
      def say_info(message)
        say message, :cyan unless options[:quiet]
      end

      # Display a warning message in yellow (always shown).
      #
      # @param message [String] the warning message to display
      # @return [void]
      def say_warning(message)
        say message, :yellow
      end

      # Get the effective limit for list output.
      #
      # @return [Integer] the limit from --limit option or default of 50
      def effective_limit
        limit = options[:limit]
        (limit.is_a?(Integer) && limit > 0) ? limit : 50
      end

      # Output an error as JSON or human-readable text.
      #
      # In JSON mode, outputs a structured error object to stdout.
      # In text mode, uses Ui.error and optionally Ui.muted for fix hints.
      #
      # @param type [String] machine-readable error type (e.g., "not_found")
      # @param message [String] human-readable error message
      # @param fix [String, nil] optional hint for how to resolve the error
      # @return [void]
      def output_error(type:, message:, fix: nil)
        if json_output?
          error_hash = {ok: false, error: {type: type, message: message}}
          error_hash[:fix] = fix if fix
          puts JSON.pretty_generate(error_hash)
        else
          Ui.error(message)
          Ui.muted(fix) if fix
        end
      end

      # Execute a block, converting not-found errors to a user-friendly Thor error.
      #
      # Wraps an API call so that ForbiddenError and NotFoundError are caught
      # and re-raised as Thor::Error with a resource-specific message.
      #
      # @param message [String] the error message to display if the resource is not found
      # @yield the block containing the API call
      # @return [Object] the return value of the block
      # @raise [Thor::Error] if the API call raises NotFoundError or ForbiddenError
      def with_not_found(message)
        yield
      rescue Superthread::ForbiddenError, Superthread::NotFoundError
        raise Thor::Error, message
      end

      # Wrap a block with consistent error handling for API operations.
      #
      # Catches API and configuration errors and displays user-friendly messages
      # (or structured JSON in --json mode) before exiting with appropriate
      # status codes.
      #
      # @yield the block to execute with error handling
      # @return [Object] the return value of the block
      def handle_error
        yield
      rescue Superthread::NotFoundError => e
        output_error(type: "not_found", message: "Not found: #{e.message}")
        exit 1
      rescue Superthread::AuthenticationError => e
        output_error(
          type: "authentication_error",
          message: "Authentication failed: #{e.message}",
          fix: "Check your API key with: suth config show"
        )
        exit 1
      rescue Superthread::ForbiddenError => e
        output_error(type: "forbidden", message: "Access denied: #{e.message}")
        exit 1
      rescue Superthread::RateLimitError => e
        output_error(
          type: "rate_limited",
          message: "Rate limited: #{e.message}",
          fix: "Try again in #{e.retry_after || 60} seconds"
        )
        exit 1
      rescue Superthread::ValidationError => e
        output_error(type: "validation_error", message: "Validation error: #{e.message}")
        exit 1
      rescue Superthread::ApiError => e
        output_error(type: "api_error", message: "API error: #{e.message}")
        exit 1
      rescue Superthread::ConfigurationError => e
        output_error(type: "configuration_error", message: "Configuration error: #{e.message}")
        exit 1
      end

      # Wrap a block with an optional confirmation prompt.
      #
      # Skips confirmation if --skip-confirm/-y flag is set, otherwise prompts
      # the user and only executes the block if they confirm.
      #
      # @param question [String] the confirmation question to display
      # @yield the block to execute if confirmed
      # @return [Object, nil] the block's return value, or nil if aborted
      def confirming(question)
        return yield if options[:skip_confirm]

        if Ui.confirm(question, default: false)
          yield
        else
          Ui.muted("Aborted")
          nil
        end
      end
    end
  end
end
