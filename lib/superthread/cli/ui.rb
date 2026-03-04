# frozen_string_literal: true

require "glamour"
require "gum"
require "io/console"
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
    module Ui
      # Brand color - purple
      PRIMARY = "#7D56F4"

      module_function

      # Display a styled header with rounded border in brand color.
      #
      # @param text [String] the header title to display
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

      # Display a section title in bold brand color without border.
      #
      # @param text [String] the section title to display
      def section(text)
        puts Gum.style(text, foreground: PRIMARY, bold: true)
      end

      # Display a success message with green checkmark prefix.
      #
      # @param text [String] the success message to display
      def success(text)
        puts Gum.style("✓ #{text}", foreground: "green", bold: true)
      end

      # Display an error message with red X prefix.
      #
      # @param text [String] the error message to display
      def error(text)
        puts Gum.style("✗ #{text}", foreground: "red", bold: true)
      end

      # Display a warning message with yellow exclamation prefix.
      #
      # @param text [String] the warning message to display
      def warning(text)
        puts Gum.style("! #{text}", foreground: "yellow", bold: true)
      end

      # Display muted text with faint styling for secondary information.
      #
      # @param text [String] the text to display in faint/dim style
      def muted(text)
        puts Gum.style(text, faint: true)
      end

      # Display informational text in brand purple color.
      #
      # @param text [String] the informational message to display
      def info(text)
        puts Gum.style(text, foreground: PRIMARY)
      end

      # Display a key-value pair with styled label.
      #
      # @param key [String] the label name to display in brand color
      # @param value [String] the value to display after the label
      def kv(key, value)
        label = Gum.style("#{key}:", foreground: PRIMARY, bold: true)
        puts "#{label} #{value}"
      end

      # Display a styled table using gum with rounded borders.
      #
      # @param rows [Array<Array>] the table data as an array of row arrays
      # @param columns [Array<String>] the column header labels
      # @note Requires a TTY. For non-interactive output, use Formatter.table instead.
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

      # Display a blank line for visual spacing between sections.
      #
      # @return [void]
      def blank
        puts ""
      end

      # Display a horizontal divider line for visual separation.
      #
      # @return [void]
      def divider
        puts Gum.style("─" * 40, faint: true)
      end

      # Prompt user for yes/no confirmation.
      #
      # @param question [String] the confirmation question to display
      # @param default [Boolean] the default answer if user presses enter
      # @return [Boolean] true if confirmed, false if declined
      def confirm(question, default: true)
        if plain_mode?
          hint = default ? "(Y/n)" : "(y/N)"
          print "#{question} #{hint}: "
          answer = $stdin.gets&.chomp
          return default if answer.nil? || answer.empty?
          answer.downcase.start_with?("y")
        else
          Gum.confirm(question, default: default)
        end
      end

      # Prompt user for single-line text input.
      #
      # @param prompt [String] the prompt label shown before the input field
      # @param placeholder [String, nil] the placeholder hint shown in empty field
      # @return [String] the text entered by the user
      def input(prompt, placeholder: nil)
        prompt = "#{prompt} " unless prompt.end_with?(" ")
        if plain_mode?
          print prompt
          $stdin.gets&.chomp
        else
          Gum.input(prompt: prompt, placeholder: placeholder)
        end
      end

      # Prompt user for password input with hidden characters.
      #
      # @param prompt [String] the prompt label shown before the input field
      # @return [String] the password entered by the user (not echoed to screen)
      def password(prompt)
        prompt = "#{prompt} " unless prompt.end_with?(" ")
        if plain_mode?
          print prompt
          $stdin.noecho(&:gets)&.chomp
        else
          Gum.input(prompt: prompt, password: true)
        end
      end

      # Prompt user to choose a single item from a list with arrow keys.
      #
      # @param items [Array<String>] the options to choose from
      # @param header [String, nil] the optional header text above the list
      # @return [String] the selected item string
      def choose(items, header: nil)
        if plain_mode?
          puts header if header
          items.each_with_index { |item, i| puts "  #{i + 1}. #{item}" }
          print "Choose (1-#{items.length}): "
          choice = $stdin.gets&.chomp&.to_i || 1
          items[choice - 1] || items.first
        else
          Gum.choose(items, header: header)
        end
      end

      # Prompt user to filter and select from a list with fuzzy search.
      #
      # Falls back to numbered list selection in plain mode.
      #
      # @param items [Array<String>] the items available for filtering
      # @param placeholder [String, nil] the placeholder hint for the search input
      # @return [String] the selected item after filtering
      def filter(items, placeholder: nil)
        if plain_mode?
          choose(items)
        else
          Gum.filter(items, placeholder: placeholder)
        end
      end

      # Show an animated spinner while executing a block.
      #
      # In plain mode, prints a status line without animation.
      #
      # @param title [String] the status message shown next to the spinner
      # @param block [Proc] the block to execute while the spinner is displayed
      # @yieldreturn [Object] the result of the long-running operation
      # @return [Object] the return value of the block
      def spin(title, &block)
        if plain_mode?
          print "#{title}..."
          result = yield
          puts " done"
          result
        else
          Gum.spin(title, spinner: :dot, &block)
        end
      end

      # Format a numeric amount as currency with negative values in red.
      #
      # @param amount [Numeric] the monetary amount to format
      # @return [String] the formatted currency string (e.g., "$12.50" or "-$5.00")
      def money(amount)
        formatted = format("$%.2f", amount.abs)
        if amount.negative?
          Gum.style("-#{formatted}", foreground: "red")
        else
          formatted
        end
      end

      # Whether to use plain Ruby I/O instead of gum interactive widgets.
      #
      # Detects Terminal.app (which renders gum's ANSI redraws incorrectly)
      # and respects the SUPERTHREAD_PLAIN env var as a manual override.
      #
      # @return [Boolean] true if interactive widgets should use plain fallbacks
      def plain_mode?
        return true if ENV["SUPERTHREAD_PLAIN"]

        ENV["TERM_PROGRAM"] == "Apple_Terminal"
      end

      # Render HTML or Markdown content with terminal-friendly styling.
      #
      # Converts HTML to Markdown first if needed, then renders with glamour
      # for syntax highlighting and formatting.
      #
      # @param content [String] the HTML or Markdown content to render
      # @param width [Integer] the word wrap width in characters
      # @return [String] the styled content suitable for terminal display
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
      rescue
        # Fall back to plain text if rendering fails
        content
      end
    end
  end
end
