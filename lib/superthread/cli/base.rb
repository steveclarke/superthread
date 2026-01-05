# frozen_string_literal: true

require "thor"
require "json"

module Superthread
  module Cli
    class Base < Thor
      def self.exit_on_failure?
        true
      end

      class_option :verbose, type: :boolean, aliases: "-v", desc: "Detailed logging"
      class_option :quiet, type: :boolean, aliases: "-q", desc: "Minimal logging"
      class_option :workspace, type: :string, aliases: "-w", desc: "Workspace ID"
      class_option :format, type: :string, default: "json", enum: %w[json table],
        desc: "Output format"

      private

      def client
        @client ||= Superthread::Client.new
      end

      def workspace_id
        ws = options[:workspace] || client.default_workspace
        return client.resolve_workspace(ws) if ws

        raise Thor::Error,
          "Workspace required. Use --workspace or set SUPERTHREAD_WORKSPACE_ID " \
          "or add workspace to ~/.config/superthread/config.yaml"
      end

      def output(data)
        case options[:format]
        when "table"
          puts format_table(data)
        else
          puts JSON.pretty_generate(data)
        end
      end

      def format_table(data)
        return "" if data.nil?

        case data
        when Hash
          format_hash_table(data)
        when Array
          format_array_table(data)
        else
          data.to_s
        end
      end

      def format_hash_table(hash)
        max_key_length = hash.keys.map { |k| k.to_s.length }.max || 0
        hash.map do |key, value|
          formatted_value = (value.is_a?(Hash) || value.is_a?(Array)) ? JSON.generate(value) : value.to_s
          "#{key.to_s.ljust(max_key_length)} : #{formatted_value}"
        end.join("\n")
      end

      def format_array_table(array)
        return "" if array.empty?

        if array.first.is_a?(Hash)
          keys = array.first.keys.take(5) # Limit columns for readability
          widths = keys.map { |k| [k.to_s.length, array.map { |r| r[k].to_s.length }.max || 0].max }

          header = keys.zip(widths).map { |k, w| k.to_s.ljust(w) }.join(" | ")
          separator = widths.map { |w| "-" * w }.join("-+-")
          rows = array.map do |row|
            keys.zip(widths).map { |k, w| row[k].to_s.truncate(w).ljust(w) }.join(" | ")
          end

          [header, separator, *rows].join("\n")
        else
          array.join("\n")
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

# String extension for table formatting
class String
  def truncate(max_length, omission: "...")
    return self if length <= max_length

    "#{self[0, max_length - omission.length]}#{omission}"
  end
end
