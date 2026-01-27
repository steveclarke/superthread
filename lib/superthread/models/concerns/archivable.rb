# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Models
    # Shared behavior modules for Superthread models.
    module Concerns
      # Provides archived status checking for models with an `archived` attribute.
      #
      # @example
      #   class Board < Superthread::Model
      #     include Concerns::Archivable
      #
      #     attribute :archived, Shale::Type::Value
      #   end
      #
      #   board.archived?  # => true/false
      module Archivable
        extend ActiveSupport::Concern

        # Check if the resource is archived.
        # The archived attribute can be a boolean or a hash with metadata.
        #
        # @return [Boolean] True if archived
        def archived?
          !!archived
        end
      end
    end
  end
end
