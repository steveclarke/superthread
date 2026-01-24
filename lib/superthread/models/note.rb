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
      include Concerns::Presentable
      include Concerns::Timestampable

      attribute :id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :team_id, Shale::Type::String
      attribute :title, Shale::Type::String
      attribute :content, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      timestamps :time_created, :time_updated
    end
  end
end
