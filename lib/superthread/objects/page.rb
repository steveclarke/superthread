# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a Superthread page (document).
    #
    # @example
    #   page = client.pages.find(workspace_id, page_id)
    #   page.title       # => "Project Overview"
    #   page.content     # => "<p>This project...</p>"
    #
    class Page < Superthread::Object
      OBJECT_NAME = 'page'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :id, :type, :team_id, :space_id, :title, :content,
                  :icon, :user_id, :time_created, :time_updated

      def initialize(data = {})
        super
        @id = @data[:id]
        @type = @data[:type]
        @team_id = @data[:team_id]
        @space_id = @data[:space_id]
        @title = @data[:title]
        @content = @data[:content]
        @icon = @data[:icon]
        @user_id = @data[:user_id]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
      end

      # Returns archived info if archived.
      #
      # @return [Superthread::Object, nil] Archive info
      def archived
        @archived ||= @data[:archived] && Superthread::Object.new(@data[:archived])
      end

      # Check if the page is archived.
      #
      # @return [Boolean] True if archived
      def archived?
        !!@data[:archived]
      end

      # Returns time_created as a Time object.
      #
      # @return [Time, nil] Created time
      def created_at
        @time_created && Time.at(@time_created / 1000.0)
      end

      # Returns time_updated as a Time object.
      #
      # @return [Time, nil] Updated time
      def updated_at
        @time_updated && Time.at(@time_updated / 1000.0)
      end
    end
  end
end
