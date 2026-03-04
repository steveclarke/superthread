# frozen_string_literal: true

require "io/console"

module Superthread
  module Cli
    module Ui
      # Plain text prompt backend using standard Ruby I/O.
      #
      # Fallback for terminals with limited ANSI escape support
      # (e.g., macOS Terminal.app) where Gum widgets render incorrectly.
      module PlainPrompt
        module_function

        # @param question [String] the confirmation question
        # @param default [Boolean] the default answer
        # @return [Boolean]
        def confirm(question, default: true)
          hint = default ? "(Y/n)" : "(y/N)"
          print "#{question} #{hint}: "
          answer = $stdin.gets&.chomp
          return default if answer.nil? || answer.empty?
          answer.downcase.start_with?("y")
        end

        # @param prompt [String] the prompt label
        # @param placeholder [String, nil] placeholder hint (ignored in plain mode)
        # @return [String]
        def input(prompt, placeholder: nil)
          print prompt
          $stdin.gets&.chomp
        end

        # @param prompt [String] the prompt label
        # @return [String]
        def password(prompt)
          print prompt
          $stdin.noecho(&:gets)&.chomp
        end

        # @param items [Array<String>] options to choose from
        # @param header [String, nil] optional header text
        # @return [String]
        def choose(items, header: nil)
          puts header if header
          items.each_with_index { |item, i| puts "  #{i + 1}. #{item}" }
          print "Choose (1-#{items.length}): "
          choice = $stdin.gets&.chomp&.to_i || 1
          items[choice - 1] || items.first
        end

        # @param items [Array<String>] the available options presented as a numbered list
        # @param placeholder [String, nil] placeholder hint (ignored in plain mode)
        # @return [String]
        def filter(items, placeholder: nil)
          choose(items)
        end

        # @param title [String] status message
        # @yieldreturn [Object] result of the block
        # @return [Object]
        def spin(title)
          print "#{title}..."
          result = yield
          puts " done"
          result
        end
      end
    end
  end
end
