# frozen_string_literal: true

require "thor"
require "json"

module Superthread
  module Cli
    # Base class for all CLI commands.
    # Provides common options, client access, and output formatting.
    class Base < Thor
      include Concerns::Openable

      def self.exit_on_failure?
        true
      end

      class_option :verbose, type: :boolean, aliases: "-v", desc: "Detailed logging"
      class_option :quiet, type: :boolean, aliases: "-q", desc: "Minimal logging"
      class_option :workspace, type: :string, aliases: "-w", desc: "Workspace (ID or name)"
      class_option :json, type: :boolean, desc: "Output as JSON"
      class_option :account, type: :string, aliases: "-a", desc: "Use specific account"
      class_option :skip_confirm, type: :boolean, aliases: ["-y", "--yes"], desc: "Auto-confirm prompts"

      private

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

      def workspace_id
        ws = options[:workspace] || client.default_workspace
        return resolve_workspace(ws) if ws

        raise Thor::Error,
          "Workspace required. Use --workspace or set SUPERTHREAD_WORKSPACE_ID " \
          "or add workspace to ~/.config/superthread/config.yaml"
      end

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

      def looks_like_workspace_id?(value)
        # Workspace IDs are typically 8 chars, start with a letter, alphanumeric
        # Also accept test IDs like "test_workspace"
        value.match?(/\A[a-zA-Z][a-zA-Z0-9_]{5,20}\z/)
      end

      def find_workspace_by_name(name)
        @workspaces_cache ||= extract_workspaces_from_user
        @workspaces_cache.find { |w| w[:name]&.downcase == name.downcase }
      end

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

      def space_id
        resolve_space(options[:space])
      end

      def resolve_space(ref)
        return ref if ref.nil?
        return ref if looks_like_id?(ref)

        space = find_space_by_name(ref)
        return space.id if space

        raise Thor::Error, "Space not found: '#{ref}'. Use 'st spaces list' to see available spaces."
      end

      def find_space_by_name(name)
        @spaces_cache ||= client.spaces.list(workspace_id)
        @spaces_cache.find { |s| s.title&.downcase == name.downcase }
      end

      # ========================================
      # Board resolution
      # ========================================

      def board_id
        resolve_board(options[:board])
      end

      def resolve_board(ref)
        return ref if ref.nil?
        return ref if looks_like_id?(ref)

        board = find_board_by_name(ref)
        return board.id if board

        raise Thor::Error, "Board not found: '#{ref}'. Use 'st boards list --space <space>' to see available boards."
      end

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

      def load_all_boards
        spaces = client.spaces.list(workspace_id)
        spaces.flat_map do |space|
          client.boards.list(workspace_id, space_id: space.id).to_a
        rescue Superthread::ApiError
          [] # Skip spaces we can't access
        end
      end

      # ========================================
      # User resolution
      # ========================================

      def resolve_user(ref)
        return ref if ref.nil?
        return ref if looks_like_id?(ref)

        user = find_user_by_name(ref)
        return user.user_identifier if user

        raise Thor::Error, "User not found: '#{ref}'. Use 'st users members' to see available users."
      end

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

      def resolve_tag(ref)
        return ref if ref.nil?
        return ref if looks_like_id?(ref)

        tag = find_tag_by_name(ref)
        return tag.id if tag

        raise Thor::Error, "Tag not found: '#{ref}'. Use 'st cards tags' to see available tags."
      end

      def find_tag_by_name(name)
        @tags_cache ||= client.cards.tags(workspace_id, all: true)
        @tags_cache.find { |t| t.name&.downcase == name.downcase }
      end

      # ========================================
      # List resolution (requires board context)
      # ========================================

      def resolve_list(ref)
        return ref if ref.nil?
        return ref if looks_like_id?(ref)

        list = find_list_by_name(ref)
        return list.id if list

        raise Thor::Error, "List not found: '#{ref}'. Specify a board with --board to search by list name."
      end

      def find_list_by_name(name)
        return nil unless options[:board]

        # Get the board which includes its lists
        board = client.boards.find(workspace_id, board_id)
        return nil unless board.lists

        board.lists.find { |l| l.title&.downcase == name.downcase }
      end

      # ========================================
      # Helper to detect if value looks like an ID
      # ========================================

      def looks_like_id?(value)
        # IDs are typically short alphanumeric strings
        value.match?(/\A[a-zA-Z0-9_-]+\z/) && value.length <= 30
      end

      # Check if color output is enabled.
      def color_enabled?
        $stdout.tty? && !options[:quiet]
      end

      # Check if JSON output is enabled (via --json flag or config format).
      def json_output?
        options[:json] || app_config.format == "json"
      end

      # Get the configuration object.
      # Named app_config to avoid collision with Thor's subcommand delegation
      # (Thor generates a `config` method for the `config` subcommand).
      def app_config
        @app_config ||= Superthread::Configuration.new
      end

      # Output a single item.
      # In JSON mode, outputs as JSON. Otherwise, outputs as key-value pairs.
      #
      # @param item [Object] Item to output
      # @param fields [Array<Symbol>] Fields to display in table mode
      # @param labels [Hash<Symbol, String>] Custom field labels
      def output_item(item, fields: nil, labels: {})
        if json_output?
          puts Formatter.json(item)
        else
          fields ||= default_detail_fields(item)
          puts Formatter.detail(item, fields: fields, labels: labels, color_enabled: color_enabled?)
        end
      end

      # Output a collection/list.
      # In JSON mode, outputs as JSON array. Otherwise, outputs as table.
      #
      # @param items [Array, Collection] Items to output
      # @param columns [Array<Symbol>] Columns to display in table mode
      # @param headers [Hash<Symbol, String>] Custom column headers
      def output_list(items, columns: nil, headers: {})
        if json_output?
          puts Formatter.json(items)
        else
          columns ||= default_list_columns(items)
          result = Formatter.table(items, columns: columns, headers: headers, color_enabled: color_enabled?)
          if result.empty?
            say "No items found.", :yellow unless options[:quiet]
          else
            puts result
          end
        end
      end

      # Output raw data (legacy support for commands not yet updated).
      # In JSON mode or when data is not an object, outputs as JSON.
      #
      # @param data [Object] Data to output
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

      # Output a success message.
      #
      # @param message [String] Message to display
      def output_success(message)
        if json_output?
          puts Formatter.json({success: true, message: message})
        else
          say message, :green unless options[:quiet]
        end
      end

      # Default detail fields based on item type.
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
          %i[id title description space_id time_created]
        when Superthread::Models::List
          %i[id title color position board_id]
        when Superthread::Models::User
          %i[user_id display_name email role]
        when Superthread::Models::Project
          %i[id title status start_date due_date]
        when Superthread::Models::Space
          %i[id title description time_created]
        when Superthread::Models::Sprint
          %i[id title status start_date due_date]
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

      # Default list columns based on item type.
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

      # Helper to get symbolized options for passing to API methods.
      #
      # @param keys [Array<Symbol>] Keys to extract
      # @return [Hash] Hash with symbol keys
      def symbolized_options(*keys)
        keys.each_with_object({}) do |key, hash|
          value = options[key.to_s]
          hash[key] = value unless value.nil?
        end
      end

      # Truncate content for display in confirmation prompts.
      # Strips HTML tags and truncates to max_length characters.
      #
      # @param content [String] Content to truncate (may contain HTML)
      # @param max_length [Integer] Maximum length (default: 50)
      # @return [String] Truncated plain text
      def truncate_content(content, max_length: 50)
        return "" if content.nil? || content.empty?

        # Strip HTML tags and normalize whitespace
        plain = content.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip
        return plain if plain.length <= max_length

        "#{plain[0, max_length]}..."
      end

      def say_info(message)
        say message, :cyan unless options[:quiet]
      end

      def say_success(message)
        say message, :green unless options[:quiet]
      end

      def say_warning(message)
        say message, :yellow
      end

      # Wraps a block with consistent error handling.
      # Catches API and configuration errors and displays user-friendly messages.
      #
      # @yield Block to execute
      # @return [Object] Block return value
      def handle_error
        yield
      rescue Superthread::NotFoundError => e
        Ui.error("Not found: #{e.message}")
        exit 1
      rescue Superthread::AuthenticationError => e
        Ui.error("Authentication failed: #{e.message}")
        Ui.muted("Check your API key with: st config show")
        exit 1
      rescue Superthread::ForbiddenError => e
        Ui.error("Access denied: #{e.message}")
        exit 1
      rescue Superthread::RateLimitError => e
        Ui.error("Rate limited: #{e.message}")
        Ui.muted("Try again in #{e.retry_after || 60} seconds")
        exit 1
      rescue Superthread::ValidationError => e
        Ui.error("Validation error: #{e.message}")
        exit 1
      rescue Superthread::ApiError => e
        Ui.error("API error: #{e.message}")
        exit 1
      rescue Superthread::ConfigurationError => e
        Ui.error("Configuration error: #{e.message}")
        exit 1
      end

      # Wraps a block with confirmation prompt.
      # Skips confirmation if --skip-confirm/-y flag is set.
      #
      # @param question [String] Confirmation question
      # @yield Block to execute if confirmed
      # @return [Object] Block return value or nil if aborted
      def confirming(question)
        return yield if options[:skip_confirm]

        if Ui.confirm(question, default: false)
          yield
        else
          Ui.muted("Aborted")
          nil
        end
      end

      # Wraps a block with a spinner.
      #
      # @param title [String] Spinner message
      # @yield Block to execute
      # @return [Object] Block return value
      def with_spinner(title, &block)
        Ui.spin(title, &block)
      end

      # Access to UI module.
      #
      # @return [Module] The Ui module
      def ui
        Ui
      end
    end
  end
end
