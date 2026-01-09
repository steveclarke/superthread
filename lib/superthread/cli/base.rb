# frozen_string_literal: true

require 'thor'
require 'json'

module Superthread
  module Cli
    # Base class for all CLI commands.
    # Provides common options, client access, and output formatting.
    class Base < Thor
      def self.exit_on_failure?
        true
      end

      class_option :verbose, type: :boolean, aliases: '-v', desc: 'Detailed logging'
      class_option :quiet, type: :boolean, aliases: '-q', desc: 'Minimal logging'
      class_option :workspace, type: :string, aliases: '-w', desc: 'Workspace ID'
      class_option :json, type: :boolean, desc: 'Output as JSON'

      private

      def client
        @client ||= Superthread::Client.new
      end

      def workspace_id
        ws = options[:workspace] || client.default_workspace
        return client.resolve_workspace(ws) if ws

        raise Thor::Error,
              'Workspace required. Use --workspace or set SUPERTHREAD_WORKSPACE_ID ' \
              'or add workspace to ~/.config/superthread/config.yaml'
      end

      # Check if color output is enabled.
      def color_enabled?
        $stdout.tty? && !options[:quiet]
      end

      # Output a single item.
      # In JSON mode, outputs as JSON. Otherwise, outputs as key-value pairs.
      #
      # @param item [Object] Item to output
      # @param fields [Array<Symbol>] Fields to display in table mode
      # @param labels [Hash<Symbol, String>] Custom field labels
      def output_item(item, fields: nil, labels: {})
        if options[:json]
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
        if options[:json]
          puts Formatter.json(items)
        else
          columns ||= default_list_columns(items)
          result = Formatter.table(items, columns: columns, headers: headers, color_enabled: color_enabled?)
          if result.empty?
            say 'No items found.', :yellow unless options[:quiet]
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
        if options[:json]
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
        if options[:json]
          puts Formatter.json({ success: true, message: message })
        else
          say message, :green unless options[:quiet]
        end
      end

      # Default detail fields based on item type.
      def default_detail_fields(item)
        case item
        when Superthread::Objects::Card
          %i[id title status priority list_title board_title time_created time_updated]
        when Superthread::Objects::Board
          %i[id title description space_id time_created]
        when Superthread::Objects::User
          %i[user_id display_name email role]
        when Superthread::Objects::Project
          %i[id title status start_date due_date]
        when Superthread::Objects::Space
          %i[id title description time_created]
        when Superthread::Objects::Sprint
          %i[id title status start_date due_date]
        when Superthread::Objects::Comment
          %i[id content user_id time_created]
        when Superthread::Objects::Page
          %i[id title space_id time_created time_updated]
        when Superthread::Objects::Note
          %i[id title time_created]
        when Superthread::Objects::Tag
          %i[id name color total_cards]
        else
          item.respond_to?(:keys) ? item.keys.take(10) : []
        end
      end

      # Default list columns based on item type.
      def default_list_columns(items)
        first = items.respond_to?(:first) ? items.first : nil
        return [] if first.nil?

        case first
        when Superthread::Objects::Card
          %i[id title status priority list_title]
        when Superthread::Objects::Board
          %i[id title]
        when Superthread::Objects::User
          %i[user_id display_name email]
        when Superthread::Objects::Project
          %i[id title status]
        when Superthread::Objects::Space
          %i[id title]
        when Superthread::Objects::Sprint
          %i[id title status]
        when Superthread::Objects::Comment
          %i[id content user_id]
        when Superthread::Objects::Page
          %i[id title]
        when Superthread::Objects::Note
          %i[id title]
        when Superthread::Objects::Tag
          %i[id name color]
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

      def say_info(message)
        say message, :cyan unless options[:quiet]
      end

      def say_success(message)
        say message, :green unless options[:quiet]
      end

      def say_warning(message)
        say message, :yellow
      end
    end
  end
end
