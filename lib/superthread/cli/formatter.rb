# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module Superthread
  module Cli
    # Formatter for CLI output in gh-style format.
    # Provides colored tables, key-value displays, and JSON output.
    #
    # @example
    #   formatter = Formatter.new(color: true)
    #   formatter.table(cards, columns: [:id, :title, :status])
    #   formatter.detail(card, fields: [:id, :title, :status, :priority])
    module Formatter
      # ANSI color codes
      COLORS = {
        reset: "\e[0m",
        bold: "\e[1m",
        dim: "\e[2m",
        red: "\e[31m",
        green: "\e[32m",
        yellow: "\e[33m",
        blue: "\e[34m",
        magenta: "\e[35m",
        cyan: "\e[36m",
        white: "\e[37m",
        gray: "\e[90m"
      }.freeze

      # Status colors for different states
      STATUS_COLORS = {
        "started" => :yellow,
        "in_progress" => :yellow,
        "done" => :green,
        "completed" => :green,
        "closed" => :green,
        "blocked" => :red,
        "active" => :green,
        "planned" => :cyan,
        "archived" => :gray
      }.freeze

      # Priority colors and labels (4=urgent, 3=high, 2=medium, 1=low)
      PRIORITY_COLORS = {
        4 => :red,      # urgent
        3 => :yellow,   # high
        2 => :blue,     # medium
        1 => :gray      # low
      }.freeze

      # Human-readable labels for priority levels.
      # @return [Hash{Integer => String}]
      PRIORITY_LABELS = {
        4 => "urgent",
        3 => "high",
        2 => "medium",
        1 => "low"
      }.freeze

      module_function

      # Truncates a string to a maximum length with an ellipsis indicator.
      #
      # @param str [String] the source string to truncate
      # @param max_length [Integer] the maximum character length for the result
      # @param omission [String] the suffix to append when truncation occurs
      # @return [String] the truncated string, or original if within limit
      def truncate(str, max_length, omission: "...")
        str = str.to_s
        return str if str.length <= max_length

        "#{str[0, max_length - omission.length]}#{omission}"
      end

      # Applies ANSI color codes to text for terminal display.
      #
      # @param text [String] the plain text to wrap with color codes
      # @param color [Symbol] the color name from COLORS constant (e.g., :red, :green)
      # @param enabled [Boolean] whether to apply color or return plain text
      # @return [String] text wrapped with ANSI codes if enabled, otherwise plain text
      def colorize(text, color, enabled: true)
        return text.to_s unless enabled && COLORS.key?(color)

        "#{COLORS[color]}#{text}#{COLORS[:reset]}"
      end

      # Formats a workflow status with semantic color coding.
      #
      # @param status [String] the status value (e.g., "started", "done", "blocked")
      # @param color_enabled [Boolean] whether to apply ANSI color codes
      # @return [String] the status with appropriate color for its state
      def format_status(status, color_enabled: true)
        return "-" if status.nil?

        color = STATUS_COLORS.fetch(status.to_s.downcase, :white)
        colorize(status, color, enabled: color_enabled)
      end

      # Formats a priority level with human-readable label and color.
      #
      # @param priority [Integer] the priority value (1=low, 2=medium, 3=high, 4=urgent)
      # @param color_enabled [Boolean] whether to apply ANSI color codes
      # @return [String] the priority label with appropriate urgency color
      def format_priority(priority, color_enabled: true)
        return "-" if priority.nil?

        label = PRIORITY_LABELS.fetch(priority, priority.to_s)
        color = PRIORITY_COLORS.fetch(priority, :white)
        colorize(label, color, enabled: color_enabled)
      end

      # Formats a timestamp as a relative time or absolute date string.
      #
      # @param timestamp [Integer, Time] Unix timestamp in seconds or a Time object
      # @param relative [Boolean] whether to use relative format (e.g., "2d ago") or absolute
      # @return [String] the formatted time string, or "-" if nil/zero
      def format_time(timestamp, relative: true)
        return "-" if timestamp.nil? || timestamp == 0

        time = timestamp.is_a?(Time) ? timestamp : Time.at(timestamp)

        if relative
          format_relative_time(time)
        else
          time.strftime("%Y-%m-%d %H:%M")
        end
      end

      # Formats a Time object as a human-readable relative time string.
      #
      # @param time [Time] the timestamp to format relative to now
      # @return [String] relative time like "just now", "5m ago", "3d ago", or a date
      def format_relative_time(time)
        diff = Time.now - time

        case diff.abs
        when 0..59 then "just now"
        when 60..3599 then "#{(diff / 60).to_i}m ago"
        when 3600..86_399 then "#{(diff / 3600).to_i}h ago"
        when 86_400..604_799 then "#{(diff / 86_400).to_i}d ago"
        else
          time.strftime("%Y-%m-%d")
        end
      end

      # Formats a boolean value as a colored yes/no string.
      #
      # @param value [Boolean] the boolean to format
      # @param color_enabled [Boolean] whether to apply green/gray ANSI color
      # @return [String] "yes" (green) for true, "no" (gray) for false
      def format_boolean(value, color_enabled: true)
        if value
          colorize("yes", :green, enabled: color_enabled)
        else
          colorize("no", :gray, enabled: color_enabled)
        end
      end

      # Formats data as an aligned text table with headers.
      #
      # @param data [Array<Hash>, Collection] the items to display as rows
      # @param columns [Array<Symbol>] the field names to include as columns
      # @param headers [Hash{Symbol => String}] custom header labels keyed by column name
      # @param color_enabled [Boolean] whether to apply ANSI color to values
      # @return [String] the formatted table with header row and data rows
      def table(data, columns:, headers: {}, color_enabled: true)
        items = data.respond_to?(:items) ? data.items : Array(data)
        return "" if items.empty?

        # Calculate column widths
        widths = columns.map do |col|
          header = headers.fetch(col, col.to_s.upcase)
          values = items.map { |item| format_cell(item, col).to_s }
          [header.length, values.map(&:length).max || 0].max
        end

        lines = []

        # Header row
        header_row = columns.zip(widths).map do |col, width|
          colorize(headers.fetch(col, col.to_s.upcase).ljust(width), :bold, enabled: color_enabled)
        end.join("  ")
        lines << header_row

        # Data rows
        items.each do |item|
          row = columns.zip(widths).map do |col, width|
            cell = format_cell(item, col, color_enabled: color_enabled)
            # Pad without color codes
            padding = width - strip_ansi(cell).length
            padding = 0 if padding.negative?
            "#{cell}#{" " * padding}"
          end.join("  ")
          lines << row
        end

        lines.join("\n")
      end

      # Formats a single item as aligned key-value pairs for detail view.
      #
      # @param item [Hash, Object] the item to display (hash or object with to_h)
      # @param fields [Array<Symbol>] the field names to include
      # @param labels [Hash{Symbol => String}] custom labels keyed by field name
      # @param color_enabled [Boolean] whether to apply ANSI color to values
      # @return [String] the formatted detail view with aligned labels and values
      def detail(item, fields:, labels: {}, color_enabled: true)
        data = item.respond_to?(:to_h) ? item.to_h : item

        max_label_width = fields.map { |f| labels.fetch(f, humanize(f)).length }.max

        lines = fields.map do |field|
          label = labels.fetch(field, humanize(field))
          value = format_field(data, field, color_enabled: color_enabled)
          "#{colorize(label.ljust(max_label_width), :cyan, enabled: color_enabled)}  #{value}"
        end

        lines.join("\n")
      end

      # Formats data as pretty-printed JSON for output.
      #
      # @param data [Object] the data to serialize (supports arrays, hashes, and objects with to_h)
      # @return [String] the indented JSON string
      def json(data)
        obj = if data.is_a?(Array)
          # Plain arrays of model objects need to be mapped to hashes
          data.map { |item| item.respond_to?(:to_h) ? item.to_h : item }
        elsif data.respond_to?(:to_h)
          data.to_h
        else
          data
        end
        JSON.pretty_generate(obj)
      end

      # Strips ANSI escape codes from a string for width calculation.
      #
      # @param str [String] the string potentially containing ANSI escape sequences
      # @return [String] the plain text without any ANSI codes
      def strip_ansi(str)
        str.to_s.gsub(/\e\[[0-9;]*m/, "")
      end

      # Converts a symbol or string to a human-readable label.
      #
      # @param key [Symbol, String] the field name to humanize (e.g., :time_created)
      # @return [String] the humanized label with title case and proper acronyms
      def humanize(key)
        key.to_s.titleize.gsub(/\bId\b/, "ID")
      end

      # Formats a cell value for display in a table column.
      #
      # @param item [Hash, Object] the row item containing the field value
      # @param column [Symbol] the column name to extract and format
      # @param color_enabled [Boolean] whether to apply semantic color formatting
      # @return [String] the formatted cell value ready for table display
      def format_cell(item, column, color_enabled: true)
        value = item.respond_to?(column) ? item.send(column) : item[column]

        # Special case: color list_title by status
        if column == :list_title && color_enabled
          status = item.respond_to?(:status) ? item.status : item[:status]
          if status
            color = STATUS_COLORS.fetch(status.to_s.downcase, :white)
            return colorize(value || "-", color, enabled: true)
          end
        end

        format_value(value, column, color_enabled: color_enabled)
      end

      # Formats a field value for display in a detail key-value view.
      #
      # @param data [Hash] the hash containing field values
      # @param field [Symbol] the field name to extract and format
      # @param color_enabled [Boolean] whether to apply semantic color formatting
      # @return [String] the formatted field value ready for detail display
      def format_field(data, field, color_enabled: true)
        value = data[field]

        # Special case: color list_title by status
        if field == :list_title && color_enabled
          status = data[:status]
          if status
            color = STATUS_COLORS.fetch(status.to_s.downcase, :white)
            return colorize(value || "-", color, enabled: true)
          end
        end

        format_value(value, field, color_enabled: color_enabled)
      end

      # Formats a value based on its field name with appropriate type handling.
      #
      # @param value [Object] the raw value to format
      # @param name [Symbol] the field name used to determine formatting rules
      # @param color_enabled [Boolean] whether to apply semantic color formatting
      # @return [String] the formatted value string, or "-" if nil
      def format_value(value, name, color_enabled: true)
        return "-" if value.nil?

        case name
        when :status
          format_status(value, color_enabled: color_enabled)
        when :priority
          format_priority(value, color_enabled: color_enabled)
        when :archived, :is_watching, :is_bookmarked, :checked
          format_boolean(value, color_enabled: color_enabled)
        when :time_created, :time_updated
          # Use relative time for creation/update timestamps
          format_time(value, relative: true)
        when :start_date, :due_date, :completed_date
          # Use absolute dates for explicit date fields
          format_time(value, relative: false)
        when :title, :content, :description
          truncate(value.to_s, 60)
        when :tags
          Array(value).map { |t| t.respond_to?(:name) ? t.name : t.to_s }.join(", ")
        when :members
          Array(value).map { |m|
            if m.respond_to?(:user_id)
              m.user_id
            elsif m.is_a?(Hash)
              m[:user_id] || m["user_id"]
            else
              m.to_s
            end
          }.join(", ")
        when Array
          value.join(", ")
        else
          value.to_s
        end
      end
    end
  end
end
