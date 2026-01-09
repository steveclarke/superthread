# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a Superthread tag/label.
    #
    # @example
    #   tag = card.tags.first
    #   tag.name         # => "bug"
    #   tag.color        # => "red"
    #   tag.total_cards  # => 17
    #
    class Tag < Superthread::Object
      OBJECT_NAME = 'tag'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :id, :team_id, :project_id, :name, :slug, :color, :total_cards

      def initialize(data = {})
        super
        @id = @data[:id]
        @team_id = @data[:team_id]
        @project_id = @data[:project_id]
        @name = @data[:name]
        @slug = @data[:slug]
        @color = @data[:color]
        @total_cards = @data[:total_cards]
      end

      # String representation.
      #
      # @return [String] Tag name
      def to_s
        @name
      end
    end
  end
end
