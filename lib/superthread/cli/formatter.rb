# frozen_string_literal: true

module Superthread
  module Cli
    # Formatter for CLI output in gh-style format.
    # Provides colored tables, key-value displays, and JSON output.
    #
    # @example
    #   formatter = Formatter.new(color: true)
    #   formatter.table(cards, columns: [:id, :title, :status])
    #   formatter.detail(card, fields: [:id, :title, :status, :priority])
    #
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
        'started' => :yellow,
        'in_progress' => :yellow,
        'done' => :green,
        'completed' => :green,
        'closed' => :green,
        'blocked' => :red,
        'active' => :green,
        'planned' => :cyan,
        'archived' => :gray
      }.freeze

      # Priority colors and labels
      PRIORITY_COLORS = {
        1 => :red,      # urgent
        2 => :yellow,   # high
        3 => :blue,     # medium
        4 => :gray      # low
      }.freeze

      PRIORITY_LABELS = {
        1 => 'urgent',
        2 => 'high',
        3 => 'medium',
        4 => 'low'
      }.freeze

      module_function

      # Truncates a string to a maximum length.
      #
      # @param str [String] The string to truncate
      # @param max_length [Integer] Maximum length
      # @param omission [String] String to append when truncated
      # @return [String] Truncated string
      def truncate(str, max_length, omission: '...')
        str = str.to_s
        return str if str.length <= max_length

        "#{str[0, max_length - omission.length]}#{omission}"
      end

      # Applies color to text if color is enabled.
      #
      # @param text [String] Text to colorize
      # @param color [Symbol] Color name
      # @param enabled [Boolean] Whether color is enabled
      # @return [String] Colorized text
      def colorize(text, color, enabled: true)
        return text.to_s unless enabled && COLORS.key?(color)

        "#{COLORS[color]}#{text}#{COLORS[:reset]}"
      end

      # Formats a status with appropriate color.
      #
      # @param status [String] Status value
      # @param color_enabled [Boolean] Whether color is enabled
      # @return [String] Formatted status
      def format_status(status, color_enabled: true)
        return '-' if status.nil?

        color = STATUS_COLORS.fetch(status.to_s.downcase, :white)
        colorize(status, color, enabled: color_enabled)
      end

      # Formats a priority with label and color.
      #
      # @param priority [Integer] Priority value (1-4)
      # @param color_enabled [Boolean] Whether color is enabled
      # @return [String] Formatted priority
      def format_priority(priority, color_enabled: true)
        return '-' if priority.nil?

        label = PRIORITY_LABELS.fetch(priority, priority.to_s)
        color = PRIORITY_COLORS.fetch(priority, :white)
        colorize(label, color, enabled: color_enabled)
      end

      # Formats a timestamp as a relative time or date.
      #
      # @param timestamp [Integer, Time] Unix timestamp in milliseconds or Time object
      # @param relative [Boolean] Use relative time (e.g., "2 days ago")
      # @return [String] Formatted time
      def format_time(timestamp, relative: true)
        return '-' if timestamp.nil?

        time = timestamp.is_a?(Time) ? timestamp : Time.at(timestamp / 1000.0)

        if relative
          format_relative_time(time)
        else
          time.strftime('%Y-%m-%d %H:%M')
        end
      end

      # Formats a relative time string.
      #
      # @param time [Time] Time to format
      # @return [String] Relative time string
      def format_relative_time(time)
        diff = Time.now - time

        case diff.abs
        when 0..59 then 'just now'
        when 60..3599 then "#{(diff / 60).to_i}m ago"
        when 3600..86_399 then "#{(diff / 3600).to_i}h ago"
        when 86_400..604_799 then "#{(diff / 86_400).to_i}d ago"
        else time.strftime('%b %d')
        end
      end

      # Formats a boolean value.
      #
      # @param value [Boolean] Boolean value
      # @param color_enabled [Boolean] Whether color is enabled
      # @return [String] Formatted boolean
      def format_boolean(value, color_enabled: true)
        if value
          colorize('yes', :green, enabled: color_enabled)
        else
          colorize('no', :gray, enabled: color_enabled)
        end
      end

      # Formats data as a table.
      #
      # @param data [Array<Hash>, Collection] Data to format
      # @param columns [Array<Symbol>] Columns to display
      # @param headers [Hash<Symbol, String>] Custom column headers
      # @param color_enabled [Boolean] Whether color is enabled
      # @return [String] Formatted table
      def table(data, columns:, headers: {}, color_enabled: true)
        items = data.respond_to?(:items) ? data.items : Array(data)
        return '' if items.empty?

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
        end.join('  ')
        lines << header_row

        # Data rows
        items.each do |item|
          row = columns.zip(widths).map do |col, width|
            cell = format_cell(item, col, color_enabled: color_enabled)
            # Pad without color codes
            padding = width - strip_ansi(cell).length
            padding = 0 if padding.negative?
            "#{cell}#{' ' * padding}"
          end.join('  ')
          lines << row
        end

        lines.join("\n")
      end

      # Formats a single item as key-value pairs.
      #
      # @param item [Hash, Object] Item to format
      # @param fields [Array<Symbol>] Fields to display
      # @param labels [Hash<Symbol, String>] Custom field labels
      # @param color_enabled [Boolean] Whether color is enabled
      # @return [String] Formatted detail view
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

      # Formats as JSON.
      #
      # @param data [Object] Data to format
      # @return [String] JSON string
      def json(data)
        obj = data.respond_to?(:to_h) ? data.to_h : data
        JSON.pretty_generate(obj)
      end

      # Strips ANSI color codes from a string.
      #
      # @param str [String] String with ANSI codes
      # @return [String] Plain string
      def strip_ansi(str)
        str.to_s.gsub(/\e\[[0-9;]*m/, '')
      end

      # Humanizes a symbol or string.
      #
      # @param key [Symbol, String] Key to humanize
      # @return [String] Humanized string
      def humanize(key)
        key.to_s.tr('_', ' ').capitalize
      end

      # Formats a cell value for a table.
      #
      # @param item [Hash, Object] Item containing the value
      # @param column [Symbol] Column/field name
      # @param color_enabled [Boolean] Whether color is enabled
      # @return [String] Formatted cell value
      def format_cell(item, column, color_enabled: true)
        value = item.respond_to?(column) ? item.send(column) : item[column]
        format_value(value, column, color_enabled: color_enabled)
      end

      # Formats a field value for detail view.
      #
      # @param data [Hash] Data hash
      # @param field [Symbol] Field name
      # @param color_enabled [Boolean] Whether color is enabled
      # @return [String] Formatted field value
      def format_field(data, field, color_enabled: true)
        value = data[field]
        format_value(value, field, color_enabled: color_enabled)
      end

      # Formats a value based on its name and type.
      #
      # @param value [Object] Value to format
      # @param name [Symbol] Field/column name
      # @param color_enabled [Boolean] Whether color is enabled
      # @return [String] Formatted value
      def format_value(value, name, color_enabled: true)
        return '-' if value.nil?

        case name
        when :status
          format_status(value, color_enabled: color_enabled)
        when :priority
          format_priority(value, color_enabled: color_enabled)
        when :archived, :is_watching, :is_bookmarked, :checked
          format_boolean(value, color_enabled: color_enabled)
        when :time_created, :time_updated, :start_date, :due_date, :completed_date
          format_time(value)
        when :title, :content, :description
          truncate(value.to_s, 60)
        when :tags
          Array(value).map { |t| t.respond_to?(:name) ? t.name : t.to_s }.join(', ')
        when :members
          Array(value).map { |m| m.respond_to?(:user_id) ? m.user_id : m.to_s }.join(', ')
        when Array
          value.join(', ')
        else
          value.to_s
        end
      end
    end
  end
end
