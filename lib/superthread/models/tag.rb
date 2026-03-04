# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread tag/label.
    #
    # Tags are colored labels that can be applied to cards for categorization
    # and filtering. They track how many cards use each tag.
    #
    # @example
    #   tag = card.tags.first
    #   tag.name         # => "bug"
    #   tag.color        # => "red"
    #   tag.total_cards  # => 17
    class Tag < Superthread::Model
      include Concerns::Presentable

      presents_as :name

      detail_fields :id, :name, :color, :total_cards
      list_columns :id, :name, :color

      # @!attribute [rw] id
      #   @return [String] unique tag identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] team_id
      #   @return [String] ID of the team/workspace this tag belongs to
      attribute :team_id, Shale::Type::String

      # @!attribute [rw] project_id
      #   @return [String] ID of the project this tag is scoped to, if any
      attribute :project_id, Shale::Type::String

      # @!attribute [rw] name
      #   @return [String] display name of the tag
      attribute :name, Shale::Type::String

      # @!attribute [rw] slug
      #   @return [String] URL-safe version of the tag name
      attribute :slug, Shale::Type::String

      # @!attribute [rw] color
      #   @return [String] color code for visual styling
      attribute :color, Shale::Type::String

      # @!attribute [rw] total_cards
      #   @return [Integer] number of cards using this tag
      attribute :total_cards, Shale::Type::Integer
    end
  end
end
