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
      # @example With block for custom formatting
      #   class Checklist < Superthread::Model
      #     include Concerns::Presentable
      #     presents_as(:title) { "#{title} (#{completed_count}/#{total_count})" }
      #   end
      #
      #   checklist.to_s  # => "Requirements (2/3)"
      #
      module Presentable
        extend ActiveSupport::Concern

        included do
          @presentation_attribute = :title
          @presentation_block = nil
        end

        class_methods do
          # Configure which attribute to use for string representation.
          # Optionally accepts a block for custom formatting.
          #
          # @param attribute [Symbol] The attribute name to use for to_s
          # @yield Block evaluated in instance context for custom formatting
          def presents_as(attribute, &block)
            @presentation_attribute = attribute
            @presentation_block = block
          end

          # Get the configured presentation attribute.
          #
          # @return [Symbol] The attribute name
          def presentation_attribute
            @presentation_attribute || :title
          end

          # Get the configured presentation block.
          #
          # @return [Proc, nil] The block or nil
          def presentation_block
            @presentation_block
          end
        end

        # String representation using the configured attribute or block.
        #
        # @return [String] The string value
        def to_s
          if self.class.presentation_block
            instance_eval(&self.class.presentation_block).to_s
          else
            send(self.class.presentation_attribute).to_s
          end
        end
      end
    end
  end
end
