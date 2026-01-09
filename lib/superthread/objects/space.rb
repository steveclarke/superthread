# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a Superthread space.
    #
    # @example
    #   space = client.spaces.find(workspace_id, space_id)
    #   space.title       # => "Engineering"
    #   space.members     # => [#<Superthread::Objects::Member ...>]
    #
    class Space < Superthread::Object
      OBJECT_NAME = 'space'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :id, :type, :team_id, :title, :description, :icon,
                  :user_id, :time_created, :time_updated

      def initialize(data = {})
        super
        @id = @data[:id]
        @type = @data[:type]
        @team_id = @data[:team_id]
        @title = @data[:title]
        @description = @data[:description]
        @icon = @data[:icon]
        @user_id = @data[:user_id]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
      end

      # Returns members as Member objects.
      #
      # @return [Array<Superthread::Objects::Member>] Space members
      def members
        @members ||= (@data[:members] || []).map { |m| Member.new(m) }
      end

      # Returns archived info if archived.
      #
      # @return [Superthread::Object, nil] Archive info
      def archived
        @archived ||= @data[:archived] && Superthread::Object.new(@data[:archived])
      end

      # Check if the space is archived.
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
