# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Models
    module Concerns
      # Provides string representation via a configurable attribute.
      # Default uses :title, but can be customized.
      #
      # @example Default (uses title)
      #   class Board < Superthread::Model
      #     include Concerns::Presentable
      #
      #     attribute :title, Shale::Type::String
      #   end
      #
      #   board.to_s  # => "My Board"
      #
      # @example Custom attribute
      #   class User < Superthread::Model
      #     include Concerns::Presentable
      #     presents_as :display_name
      #
      #     attribute :display_name, Shale::Type::String
      #   end
      #
      #   user.to_s  # => "John Doe"
      #
      module Presentable
        extend ActiveSupport::Concern

        included do
          @presentation_attribute = :title
        end

        class_methods do
          # Configure which attribute to use for string representation.
          #
          # @param attribute [Symbol] The attribute name to use for to_s
          def presents_as(attribute)
            @presentation_attribute = attribute
          end

          # Get the configured presentation attribute.
          #
          # @return [Symbol] The attribute name
          def presentation_attribute
            @presentation_attribute || :title
          end
        end

        # String representation using the configured attribute.
        #
        # @return [String] The string value of the presentation attribute
        def to_s
          send(self.class.presentation_attribute).to_s
        end
      end
    end
  end
end
