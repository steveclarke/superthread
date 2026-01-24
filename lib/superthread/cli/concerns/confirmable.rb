# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Cli
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
      #
      module Confirmable
        extend ActiveSupport::Concern

        # Execute a block with optional confirmation prompt.
        # Skips confirmation if --force flag is set.
        #
        # @param message [String] The confirmation message to display
        # @yield The block to execute if confirmed
        # @return [Object] The result of the block
        def confirming(message)
          if options[:force] || confirm_action(message)
            yield
          else
            Ui.muted "Cancelled."
          end
        end

        private

        # Prompt user for confirmation.
        #
        # @param message [String] The confirmation message
        # @return [Boolean] True if user confirms
        def confirm_action(message)
          Ui.confirm(message)
        end
      end
    end
  end
end
