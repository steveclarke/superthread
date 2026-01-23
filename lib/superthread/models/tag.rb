# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread tag/label.
    #
    # @example
    #   tag = card.tags.first
    #   tag.name         # => "bug"
    #   tag.color        # => "red"
    #   tag.total_cards  # => 17
    #
    class Tag < Superthread::Model
      attribute :id, Shale::Type::String
      attribute :team_id, Shale::Type::String
      attribute :project_id, Shale::Type::String
      attribute :name, Shale::Type::String
      attribute :slug, Shale::Type::String
      attribute :color, Shale::Type::String
      attribute :total_cards, Shale::Type::Integer

      # String representation.
      #
      # @return [String] Tag name
      def to_s
        name.to_s
      end
    end
  end
end
