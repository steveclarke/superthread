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

      # ========================================
      # Workspace resolution
      # ========================================

      # Get the current workspace ID from options, config, or raise error.
      #
      # @return [String] the resolved workspace ID
      # @raise [Thor::Error] if no workspace is configured
      def workspace_id
        ws = options[:workspace] || client.default_workspace
        return resolve_workspace(ws) if ws

        raise Thor::Error,
          "Workspace required. Use --workspace or set SUPERTHREAD_WORKSPACE_ID " \
          "or add workspace to ~/.config/superthread/config.yaml"
      end

      # Resolve a workspace reference (ID or name) to its ID.
      #
      # @param ref [String, nil] the workspace ID or name to resolve
      # @return [String, nil] the resolved workspace ID, or nil if ref is nil
      def resolve_workspace(ref)
        return ref if ref.nil?

        # Workspace IDs look like: t4k7Wa2e (8 chars, alphanumeric, starts with letter)
        # Skip resolution for ID-like values to avoid unnecessary API calls
        return ref if looks_like_workspace_id?(ref)

        # Try name resolution for name-like values
        workspace = find_workspace_by_name(ref)
        return workspace[:id] if workspace

        # Fall back to treating it as an ID (might still work)
        ref
      end

      # Check if a value looks like a workspace ID (alphanumeric, starts with letter).
      #
      # @param value [String] the value to check
      # @return [Boolean] true if it matches workspace ID pattern
      def looks_like_workspace_id?(value)
        # Workspace IDs are typically 8 chars, start with a letter, alphanumeric
        # Also accept test IDs like "test_workspace"
        value.match?(/\A[a-zA-Z][a-zA-Z0-9_]{5,20}\z/)
      end

      # Find a workspace by name from the cached list.
      #
      # @param name [String] the workspace name to search for (case-insensitive)
      # @return [Hash, nil] the workspace hash with :id and :name, or nil if not found
      def find_workspace_by_name(name)
        @workspaces_cache ||= extract_workspaces_from_user
        @workspaces_cache.find { |w| w[:name]&.downcase == name.downcase }
      end

      # Extract workspace list from the current user's teams.
      #
      # @return [Array<Hash{Symbol => String}>] array of workspace hashes with :id and :name
      def extract_workspaces_from_user
        user = client.users.me
        return [] unless user.teams

        user.teams.map do |team|
          {id: team.id, name: team.team_name}
        end
      end

      # ========================================
      # Space resolution
      # ========================================

      # Get the space ID from --space option, resolving name if needed.
      #
      # @return [String, nil] the resolved space ID, or nil if not specified
      def space_id
        resolve_space(options[:space])
      end

      # Resolve a space reference (ID or name) to its ID.
      #
      # @param ref [String, nil] the space ID or name to resolve
      # @return [String, nil] the resolved space ID
      # @raise [Thor::Error] if name is provided but not found
      def resolve_space(ref)
        return ref if ref.nil?

        # Try name resolution first, then fall back to assuming it's an ID
        space = find_space_by_name(ref)
        return space.id if space

        # Assume it's an ID if name lookup failed
        ref
      end

      # Find a space by name from the cached list.
      #
      # @param name [String] the space name to search for (case-insensitive)
      # @return [Superthread::Models::Space, nil] the space object or nil if not found
      def find_space_by_name(name)
        @spaces_cache ||= client.spaces.list(workspace_id)
        @spaces_cache.find { |s| s.title&.downcase == name.downcase }
      end

      # ========================================
      # Board resolution
      # ========================================

      # Get the board ID from --board option, resolving name if needed.
      #
      # @return [String, nil] the resolved board ID, or nil if not specified
      def board_id
        resolve_board(options[:board])
      end

      # Resolve a board reference (ID or name) to its ID.
      #
      # @param ref [String, nil] the board ID or name to resolve
      # @return [String, nil] the resolved board ID
      # @raise [Thor::Error] if name is provided but not found
      def resolve_board(ref)
        return ref if ref.nil?
        return ref if looks_like_id?(ref)

        board = find_board_by_name(ref)
        return board.id if board

        raise Thor::Error, "Board not found: '#{ref}'. Use 'suth boards list --space <space>' to see available boards."
      end

      # Find a board by name, searching within space if specified or all spaces.
      #
      # @param name [String] the board name to search for (case-insensitive)
      # @return [Superthread::Models::Board, nil] the board object or nil if not found
      def find_board_by_name(name)
        # If space is specified, search only in that space
        if options[:space]
          @boards_cache ||= client.boards.list(workspace_id, space_id: space_id)
          return @boards_cache.find { |b| b.title&.downcase == name.downcase }
        end

        # Otherwise search across all spaces
        @all_boards_cache ||= load_all_boards
        @all_boards_cache.find { |b| b.title&.downcase == name.downcase }
      end

      # Load all boards from all spaces in the workspace.
      #
      # @return [Array<Superthread::Models::Board>] all accessible boards
      def load_all_boards
        spaces = client.spaces.list(workspace_id)
        spaces.flat_map do |space|
          client.boards.list(workspace_id, space_id: space.id).to_a
        rescue Superthread::ApiError
          [] # Skip spaces we can't access
        end
      end

      # ========================================
      # Sprint resolution
      # ========================================

      # Get the sprint ID from --sprint option, resolving name if needed.
      #
      # @return [String, nil] the resolved sprint ID, or nil if not specified
      def sprint_id
        resolve_sprint(options[:sprint])
      end

      # Resolve a sprint reference (ID or name) to its ID.
      #
      # @param ref [String, nil] the sprint ID or name to resolve
      # @return [String, nil] the resolved sprint ID
      # @raise [Thor::Error] if name is provided but not found
      def resolve_sprint(ref)
        return ref if ref.nil?
        return ref if looks_like_id?(ref)

        sprint = find_sprint_by_name(ref)
        return sprint.id if sprint

        raise Thor::Error, "Sprint not found: '#{ref}'. Use 'suth sprints list -s <space>' to see available sprints."
      end

      # Find a sprint by name within the current space context.
      #
      # @param name [String] the sprint name to search for (case-insensitive)
      # @return [Superthread::Models::Sprint, nil] the sprint object or nil if not found
      # @raise [Thor::Error] if --space is not provided
      def find_sprint_by_name(name)
        unless options[:space]
          raise Thor::Error, "--space is required to resolve sprint name '#{name}'"
        end

        @sprints_cache ||= client.sprints.list(workspace_id, space_id: space_id)
        @sprints_cache.find { |s| s.title&.downcase == name.downcase }
      end

      # ========================================
      # User resolution
      # ========================================

      # Resolve a user reference (ID, name, or email) to their user identifier.
      #
      # @param ref [String, nil] the user ID, display name, or email to resolve
      # @return [String, nil] the resolved user identifier
      # @raise [Thor::Error] if name/email is provided but not found
      def resolve_user(ref)
        return ref if ref.nil?
        return ref if looks_like_id?(ref)

        user = find_user_by_name(ref)
        return user.user_identifier if user

        raise Thor::Error, "User not found: '#{ref}'. Use 'suth members list' to see available users."
      end

      # Find a user by display name or email from the cached member list.
      #
      # @param name [String] the display name or email to search for (case-insensitive)
      # @return [Superthread::Models::User, nil] the user object or nil if not found
      def find_user_by_name(name)
        @users_cache ||= client.users.members(workspace_id)
        @users_cache.find do |u|
          u.display_name&.downcase == name.downcase ||
            u.email&.downcase == name.downcase
        end
      end

      # ========================================
      # Tag resolution
      # ========================================

      # Resolve a tag reference (ID or name) to its ID.
      #
      # Tag names are often short alphanumeric strings (e.g., "bug", "feature")
      # that would otherwise look like IDs, so we try name resolution first.
      #
      # @param ref [String, nil] the tag ID or name to resolve
      # @return [String, nil] the resolved tag ID
      # @raise [Thor::Error] if ref doesn't match a tag name and doesn't look like an ID
      def resolve_tag(ref)
        return ref if ref.nil?

        # Try name resolution first (tags commonly have simple names)
        tag = find_tag_by_name(ref)
        return tag.id if tag

        # If not found by name, assume it's an ID
        return ref if looks_like_id?(ref)

        raise Thor::Error, "Tag not found: '#{ref}'. Use 'suth tags list' to see available tags."
      end

      # Find a tag by name from the cached list.
      #
      # @param name [String] the tag name to search for (case-insensitive)
      # @return [Superthread::Models::Tag, nil] the tag object or nil if not found
      def find_tag_by_name(name)
        @tags_cache ||= client.cards.tags(workspace_id, all: true)
        @tags_cache.find { |t| t.name&.downcase == name.downcase }
      end

      # ========================================
      # List resolution (requires board context)
      # ========================================

      # Resolve a list reference (ID or name) to its ID.
      #
      # @param ref [String, nil] the list ID or name to resolve
      # @return [String, nil] the resolved list ID
      # @raise [Thor::Error] if name is provided but not found
      def resolve_list(ref)
        return ref if ref.nil?
        return ref if looks_like_id?(ref)

        list = find_list_by_name(ref)
        return list.id if list

        raise Thor::Error, "List not found: '#{ref}'. Specify --board or --sprint to search by list name."
      end

      # Find a list by name within the current board or sprint context.
      #
      # @param name [String] the list name to search for (case-insensitive)
      # @return [Superthread::Models::List, nil] the list object or nil if not found
      def find_list_by_name(name)
        lists = if options[:board]
          board = client.boards.find(workspace_id, board_id)
          board.lists
        elsif options[:sprint]
          sprint = client.sprints.find(workspace_id, sprint_id, space_id: space_id)
          sprint.lists
        end

        return nil unless lists

        lists.find { |l| l.title&.downcase == name.downcase }
      end

      # ========================================
      # Helper to detect if value looks like an ID
      # ========================================

      # Check if a value looks like a resource ID (alphanumeric, reasonable length).
      #
      # @param value [String] the value to check
      # @return [Boolean] true if it matches ID pattern
      def looks_like_id?(value)
        # IDs are short alphanumeric strings or full UUIDs (36 chars with hyphens)
        value.match?(/\A[a-zA-Z0-9_-]+\z/) && value.length <= 36
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
        case item
        when Superthread::Models::Card
          %i[id title status priority list_title board_title time_created time_updated]
        when Superthread::Models::Checklist
          %i[id title card_id time_created]
        when Superthread::Models::ChecklistItem
          %i[id title checked checklist_id]
        when Superthread::Models::Tag
          %i[id name color total_cards]
        when Superthread::Models::Board
          %i[id title time_created time_updated]
        when Superthread::Models::List
          %i[id title color position board_id]
        when Superthread::Models::User
          %i[user_id display_name email role]
        when Superthread::Models::Project
          %i[id title status start_date due_date]
        when Superthread::Models::Space
          %i[id title description time_created]
        when Superthread::Models::Sprint
          %i[id title start_date time_created time_updated]
        when Superthread::Models::Comment
          %i[id content user_id time_created]
        when Superthread::Models::Page
          %i[id title space_id time_created time_updated]
        when Superthread::Models::Note
          %i[id title time_created]
        else
          item.respond_to?(:keys) ? item.keys.take(10) : []
        end
      end

      # Get default list columns based on the first item's model type.
      #
      # @param items [Array, Collection] the items to determine columns for
      # @return [Array<Symbol>] the default columns for this collection type
      def default_list_columns(items)
        first = items.respond_to?(:first) ? items.first : nil
        return [] if first.nil?

        case first
        when Superthread::Models::Card
          %i[id title status priority list_title]
        when Superthread::Models::Checklist
          %i[id title]
        when Superthread::Models::ChecklistItem
          %i[id title checked]
        when Superthread::Models::Tag
          %i[id name color]
        when Superthread::Models::Board
          %i[id title]
        when Superthread::Models::List
          %i[id title color]
        when Superthread::Models::User
          %i[user_id display_name email]
        when Superthread::Models::Project
          %i[id title status]
        when Superthread::Models::Space
          %i[id title]
        when Superthread::Models::Sprint
          %i[id title status]
        when Superthread::Models::Comment
          %i[id content user_id]
        when Superthread::Models::Page
          %i[id title]
        when Superthread::Models::Note
          %i[id title]
        else
          first.respond_to?(:keys) ? first.keys.take(5) : []
        end
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

      # Display a success message in green unless quiet mode.
      #
      # @param message [String] the success message to display
      # @return [void]
      def say_success(message)
        say message, :green unless options[:quiet]
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

      # Wrap a block with an animated spinner for long operations.
      #
      # @param title [String] the status message shown during execution
      # @param block [Proc] the block to execute while spinner is displayed
      # @yieldreturn [Object] the result of the long-running operation
      # @return [Object] the return value of the block
      def with_spinner(title, &block)
        Ui.spin(title, &block)
      end

      # Access the UI module for terminal output helpers.
      #
      # @return [Module] the Ui module with styled output methods
      def ui
        Ui
      end
    end
  end
end
