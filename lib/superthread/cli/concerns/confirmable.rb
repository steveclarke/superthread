# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Cli
    # Shared behavior modules for CLI commands.
    module Concerns
      # Provides confirmation prompts for destructive actions.
      # Respects the --force flag to skip confirmation.
      #
      # @example
      #   class Cards < Base
      #     include Concerns::Confirmable
      #
      #     def delete(card_id)
      #       handle_error do
      #         confirming("Delete card #{card_id}?") do
      #           client.cards.destroy(workspace_id, card_id)
      #           Ui.success "Card #{card_id} deleted"
      #         end
      #       end
      #     end
      #   end
      module Confirmable
        extend ActiveSupport::Concern

        # Execute a block with optional confirmation prompt.
        #
        # Skips confirmation if --force flag is set, otherwise prompts user.
        #
        # @param message [String] the confirmation question to display
        # @yield the block to execute if user confirms
        # @return [Object, nil] the block's return value, or nil if cancelled
        def confirming(message)
          if options[:force] || confirm_action(message)
            yield
          else
            Ui.muted "Cancelled."
          end
        end

        private

        # Prompt user for yes/no confirmation via the UI.
        #
        # @param message [String] the confirmation question to display
        # @return [Boolean] true if user confirms, false otherwise
        def confirm_action(message)
          Ui.confirm(message)
        end
      end
    end
  end
end
