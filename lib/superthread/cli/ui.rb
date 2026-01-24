# frozen_string_literal: true

require "glamour"
require "gum"
require "reverse_markdown"

module Superthread
  module Cli
    # Terminal UI helpers using Gum for styled output.
    # Provides consistent styling across all CLI commands.
    #
    # @example
    #   Ui.header("Cards")
    #   Ui.success("Card created")
    #   Ui.table(rows, columns: ["ID", "Title", "Status"])
    #
    module Ui
      # Brand color - purple
      PRIMARY = "#7D56F4"

      module_function

      # Display a styled header with border.
      #
      # @param text [String] Header text
      def header(text)
        puts Gum.style(
          text,
          foreground: PRIMARY,
          bold: true,
          border: :rounded,
          border_foreground: PRIMARY,
          padding: "0 2"
        )
      end

      # Display a section title (no border).
      #
      # @param text [String] Section text
      def section(text)
        puts Gum.style(text, foreground: PRIMARY, bold: true)
      end

      # Display a success message with checkmark.
      #
      # @param text [String] Success message
      def success(text)
        puts Gum.style("✓ #{text}", foreground: "green", bold: true)
      end

      # Display an error message with X.
      #
      # @param text [String] Error message
      def error(text)
        puts Gum.style("✗ #{text}", foreground: "red", bold: true)
      end

      # Display a warning message.
      #
      # @param text [String] Warning message
      def warning(text)
        puts Gum.style("! #{text}", foreground: "yellow", bold: true)
      end

      # Display muted/subtle text.
      #
      # @param text [String] Text to display
      def muted(text)
        puts Gum.style(text, faint: true)
      end

      # Display info text in brand color.
      #
      # @param text [String] Text to display
      def info(text)
        puts Gum.style(text, foreground: PRIMARY)
      end

      # Display a key-value pair.
      #
      # @param key [String] Label
      # @param value [String] Value
      def kv(key, value)
        label = Gum.style("#{key}:", foreground: PRIMARY, bold: true)
        puts "#{label} #{value}"
      end

      # Display a styled table using gum.
      # Note: Requires a TTY. For non-interactive output, use Formatter.table instead.
      #
      # @param rows [Array<Array>] Table rows (array of arrays)
      # @param columns [Array<String>] Column headers
      def table(rows, columns:)
        return if rows.empty?

        Gum.table(
          rows,
          columns: columns,
          print: true,
          border: :rounded,
          header_foreground: PRIMARY
        )
        puts ""
      end

      # Display a blank line for spacing.
      def blank
        puts ""
      end

      # Display a horizontal divider.
      def divider
        puts Gum.style("─" * 40, faint: true)
      end

      # Prompt for confirmation.
      #
      # @param question [String] Question to ask
      # @param default [Boolean] Default answer
      # @return [Boolean] User's response
      def confirm(question, default: true)
        Gum.confirm(question, default: default)
      end

      # Prompt for text input.
      #
      # @param prompt [String] Input prompt
      # @param placeholder [String, nil] Placeholder text
      # @return [String] User's input
      def input(prompt, placeholder: nil)
        Gum.input(prompt: prompt, placeholder: placeholder)
      end

      # Prompt for password input (hidden).
      #
      # @param prompt [String] Input prompt
      # @return [String] User's input
      def password(prompt)
        Gum.input(prompt: prompt, password: true)
      end

      # Prompt user to choose from a list.
      #
      # @param items [Array<String>] Items to choose from
      # @param header [String, nil] Optional header
      # @return [String] Selected item
      def choose(items, header: nil)
        Gum.choose(items, header: header)
      end

      # Prompt user to filter/search a list.
      #
      # @param items [Array<String>] Items to filter
      # @param placeholder [String, nil] Search placeholder
      # @return [String] Selected item
      def filter(items, placeholder: nil)
        Gum.filter(items, placeholder: placeholder)
      end

      # Show a spinner while executing a block.
      #
      # @param title [String] Spinner title
      # @yield Block to execute
      # @return [Object] Block return value
      def spin(title, &block)
        Gum.spin(title, spinner: :dot, &block)
      end

      # Format currency (negative in red).
      #
      # @param amount [Numeric] Amount to format
      # @return [String] Formatted amount
      def money(amount)
        formatted = format("$%.2f", amount.abs)
        if amount.negative?
          Gum.style("-#{formatted}", foreground: "red")
        else
          formatted
        end
      end

      # Render HTML/Markdown content with terminal styling.
      # Converts HTML to Markdown, then renders with glamour.
      #
      # @param content [String] HTML or Markdown content
      # @param width [Integer] Word wrap width (default: 80)
      # @return [String] Rendered content for terminal display
      def render_markdown(content, width: 80)
        return "" if content.nil? || content.empty?

        # Convert HTML to Markdown if it looks like HTML
        markdown = if content.include?("<") && content.include?(">")
          ReverseMarkdown.convert(content, unknown_tags: :bypass)
        else
          content
        end

        # Render with glamour
        Glamour.render(markdown, width: width, style: "auto")
      rescue => e
        # Fall back to plain text if rendering fails
        content
      end
    end
  end
end
