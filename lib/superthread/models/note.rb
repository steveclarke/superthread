# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread note.
    #
    # @example
    #   note = client.notes.find(workspace_id, note_id)
    #   note.title       # => "Meeting Notes"
    #   note.content     # => "<p>Discussed...</p>"
    #
    class Note < Superthread::Model
      attribute :id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :team_id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :content, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

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
      # @return [String] Note title
      def to_s
        title.to_s
      end
    end
  end
end
