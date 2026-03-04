# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread page (document).
    #
    # Pages are wiki-style documents that live within spaces. They support
    # rich text content, icons, and can be archived.
    #
    # @example
    #   page = client.pages.find(workspace_id, page_id)
    #   page.title       # => "Project Overview"
    #   page.content     # => "<p>This project...</p>"
    #   page.archived?   # => false
    class Page < Superthread::Model
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

      detail_fields :id, :title, :space_id, :time_created, :time_updated
      list_columns :id, :title

      # @!attribute [rw] id
      #   @return [String] unique page identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] type
      #   @return [String] page type
      attribute :type, Shale::Type::String

      # @!attribute [rw] team_id
      #   @return [String] ID of the team/workspace this page belongs to
      attribute :team_id, Shale::Type::String

      # @!attribute [rw] space_id
      #   @return [String] ID of the space this page belongs to
      attribute :space_id, Shale::Type::String

      # @!attribute [rw] title
      #   @return [String] display title of the page
      attribute :title, Shale::Type::String

      # @!attribute [rw] content
      #   @return [String] HTML content of the page
      attribute :content, Shale::Type::String

      # @!attribute [rw] icon
      #   @return [String] emoji or icon identifier for the page
      attribute :icon, Shale::Type::String

      # @!attribute [rw] user_id
      #   @return [String] ID of the user who created the page
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the page was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the page was last updated
      attribute :time_updated, Shale::Type::Integer

      # @!attribute [rw] archived
      #   @return [Hash{String => Object}, nil] archive metadata with user_id and time_archived
      attribute :archived, Shale::Type::Value

      timestamps :time_created, :time_updated
    end
  end
end
