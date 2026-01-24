# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread page (document).
    #
    # @example
    #   page = client.pages.find(workspace_id, page_id)
    #   page.title       # => "Project Overview"
    #   page.content     # => "<p>This project...</p>"
    #   page.archived?   # => false
    #
    class Page < Superthread::Model
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

      attribute :id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :team_id, Shale::Type::String
      attribute :space_id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :content, Shale::Type::String
      attribute :icon, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      # Archived info (hash with user_id and time_archived)
      attribute :archived, Shale::Type::Value

      timestamps :time_created, :time_updated
    end
  end
end
