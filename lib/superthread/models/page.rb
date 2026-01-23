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

      # Check if the page is archived.
      #
      # @return [Boolean] True if archived
      def archived?
        !!archived
      end

      # Returns time_created as a Time object.
      #
      # @return [Time, nil] Created time
      def created_at
        ms_to_time(time_created)
      end

      # Returns time_updated as a Time object.
      #
      # @return [Time, nil] Updated time
      def updated_at
        ms_to_time(time_updated)
      end

      # String representation.
      #
      # @return [String] Page title
      def to_s
        title.to_s
      end
    end
  end
end
