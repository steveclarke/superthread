# frozen_string_literal: true

module Superthread
  module Cli
    module Ui
      # Interactive prompt backend using Gum TUI widgets.
      #
      # Provides rich terminal interactions with animated spinners,
      # arrow-key selection, and fuzzy filtering. Requires a terminal
      # with full ANSI escape sequence support.
      module GumPrompt
        module_function

        # @param question [String] the confirmation question
        # @param default [Boolean] the default answer
        # @return [Boolean]
        def confirm(question, default: true)
          Gum.confirm(question, default: default)
        end

        # @param prompt [String] the prompt label
        # @param placeholder [String, nil] placeholder hint
        # @return [String]
        def input(prompt, placeholder: nil)
          Gum.input(prompt: prompt, placeholder: placeholder)
        end

        # @param prompt [String] the prompt label
        # @return [String]
        def password(prompt)
          Gum.input(prompt: prompt, password: true)
        end

        # @param items [Array<String>] options to choose from
        # @param header [String, nil] optional header text
        # @return [String]
        def choose(items, header: nil)
          Gum.choose(items, header: header)
        end

        # @param items [Array<String>] the available options for fuzzy filtering
        # @param placeholder [String, nil] placeholder hint
        # @return [String]
        def filter(items, placeholder: nil)
          Gum.filter(items, placeholder: placeholder)
        end

        # @param title [String] status message
        # @param block [Proc] the block to execute while the spinner is displayed
        # @yieldreturn [Object] result of the block
        # @return [Object]
        def spin(title, &block)
          Gum.spin(title, spinner: :dot, &block)
        end
      end
    end
  end
end
