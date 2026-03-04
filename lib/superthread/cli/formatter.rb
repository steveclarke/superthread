# frozen_string_literal: true

require "active_support/core_ext/string/inflections"
require "unicode/display_width"

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

      # Threshold for detecting millisecond timestamps vs second timestamps.
      # Timestamps above this value are assumed to be in milliseconds.
      MAX_SECONDS_TIMESTAMP = 9_999_999_999

      module_function

      # Strips HTML tags from content and normalizes whitespace.
      #
      # @param content [String, nil] HTML content to strip
      # @return [String] plain text with tags removed and whitespace normalized
      def strip_html(content)
        content.to_s.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip
      end

      # Normalizes a timestamp to seconds (API sometimes returns milliseconds).
      #
      # @param ts [Integer, nil] timestamp in seconds or milliseconds
      # @return [Integer, nil] timestamp in seconds, or nil if nil/zero
      def normalize_timestamp(ts)
        return nil if ts.nil? || ts == 0

        (ts > MAX_SECONDS_TIMESTAMP) ? ts / 1000 : ts
      end

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
          [display_width(header), values.map { |v| display_width(v) }.max || 0].max
        end

        lines = []

        # Header row
        header_row = columns.zip(widths).map do |col, width|
          colorize(pad_right(headers.fetch(col, col.to_s.upcase), width), :bold, enabled: color_enabled)
        end.join("  ")
        lines << header_row

        # Data rows
        items.each do |item|
          row = columns.zip(widths).map do |col, width|
            cell = format_cell(item, col, color_enabled: color_enabled)
            # Pad without color codes
            padding = width - display_width(strip_ansi(cell))
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

        max_label_width = fields.map { |f| display_width(labels.fetch(f, humanize(f))) }.max

        lines = fields.map do |field|
          label = labels.fetch(field, humanize(field))
          value = format_field(data, field, color_enabled: color_enabled)
          "#{colorize(pad_right(label, max_label_width), :cyan, enabled: color_enabled)}  #{value}"
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

      # Returns the display width of a string, accounting for Unicode
      # wide characters and emoji that occupy more than one column.
      #
      # @param str [String] the string to measure
      # @return [Integer] the number of terminal columns the string occupies
      def display_width(str)
        Unicode::DisplayWidth.of(str.to_s)
      end

      # Right-pads a string to a target display width, accounting for
      # Unicode wide characters.
      #
      # @param str [String] the string to pad
      # @param target_width [Integer] the desired display width
      # @return [String] the padded string
      def pad_right(str, target_width)
        padding = target_width - display_width(str)
        padding = 0 if padding.negative?
        "#{str}#{" " * padding}"
      end

      # Converts a symbol or string to a human-readable label.
      #
      # @param key [Symbol, String] the field name to humanize (e.g., :time_created)
      # @return [String] the humanized label with title case and proper acronyms
      def humanize(key)
        str = key.to_s
        # Handle _id suffix specially since titleize treats "id" as an acronym and drops it
        if str.end_with?("_id")
          str.sub(/_id$/, "").titleize + " ID"
        else
          str.titleize
        end
      end

      # Formats a cell value for display in a table column.
      #
      # @param item [Hash, Object] the row item containing the field value
      # @param column [Symbol] the column name to extract and format
      # @param color_enabled [Boolean] whether to apply semantic color formatting
      # @return [String] the formatted cell value ready for table display
      def format_cell(item, column, color_enabled: true)
        value = item.respond_to?(column) ? item.send(column) : item[column]
        status = item.respond_to?(:status) ? item.status : item[:status]

        return color_by_status(value, status) if column == :list_title && color_enabled && status

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

        return color_by_status(value, data[:status]) if field == :list_title && color_enabled && data[:status]

        format_value(value, field, color_enabled: color_enabled)
      end

      # Colors a value based on a workflow status.
      #
      # @param value [String, nil] the text to colorize
      # @param status [String] the status used to determine color
      # @return [String] the value with ANSI color codes applied
      def color_by_status(value, status)
        color = STATUS_COLORS.fetch(status.to_s.downcase, :white)
        colorize(value || "-", color, enabled: true)
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
            if m.respond_to?(:display_name) && m.display_name
              m.display_name
            elsif m.respond_to?(:user_id)
              m.user_id
            elsif m.is_a?(Hash)
              m[:display_name] || m["display_name"] || m[:user_id] || m["user_id"]
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
