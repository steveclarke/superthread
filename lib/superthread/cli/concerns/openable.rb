# frozen_string_literal: true

module Superthread
  module Cli
    module Concerns
      # Provides browser opening functionality for CLI commands.
      # Include this concern and call open_in_browser after displaying an item.
      module Openable
        WEB_BASE_URL = "https://app.superthread.com"

        # Open an item in the browser if --open flag is set.
        #
        # @param item_type [Symbol, String] Item type (card, board, project, etc.)
        # @param item_id [String] Item ID
        def open_in_browser(item_type, item_id)
          return unless options[:open]

          url = "#{WEB_BASE_URL}/#{workspace_id}/#{item_type}s/#{item_id}"
          browser_open(url)
          Ui.muted "Opened in browser: #{url}"
        end

        private

        # Open a URL in the default browser.
        # Cross-platform: macOS (open), Linux (xdg-open), Windows (start).
        def browser_open(url)
          command = case RUBY_PLATFORM
          when /darwin/i
            "open"
          when /linux|bsd/i
            "xdg-open"
          when /mswin|mingw|cygwin/i
            "start"
          else
            "open"
          end

          system(command, url)
        end
      end
    end
  end
end
