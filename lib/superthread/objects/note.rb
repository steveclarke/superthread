# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a Superthread note.
    #
    # @example
    #   note = client.notes.find(workspace_id, note_id)
    #   note.title       # => "Meeting Notes"
    #   note.content     # => "<p>Discussed...</p>"
    #
    class Note < Superthread::Object
      OBJECT_NAME = 'note'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :id, :type, :team_id, :title, :content,
                  :user_id, :time_created, :time_updated

      def initialize(data = {})
        super
        @id = @data[:id]
        @type = @data[:type]
        @team_id = @data[:team_id]
        @title = @data[:title]
        @content = @data[:content]
        @user_id = @data[:user_id]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
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
