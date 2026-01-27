# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread note.
    #
    # Notes are standalone documents within a workspace, used for
    # meeting notes, documentation, or other text content.
    #
    # @example
    #   note = client.notes.find(workspace_id, note_id)
    #   note.title       # => "Meeting Notes"
    #   note.content     # => "<p>Discussed...</p>"
    class Note < Superthread::Model
      include Concerns::Presentable
      include Concerns::Timestampable

      # @!attribute [rw] id
      #   @return [String] unique note identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] type
      #   @return [String] note type
      attribute :type, Shale::Type::String

      # @!attribute [rw] team_id
      #   @return [String] ID of the team/workspace this note belongs to
      attribute :team_id, Shale::Type::String

      # @!attribute [rw] title
      #   @return [String] display title of the note
      attribute :title, Shale::Type::String

      # @!attribute [rw] content
      #   @return [String] HTML content of the note
      attribute :content, Shale::Type::String

      # @!attribute [rw] user_id
      #   @return [String] ID of the user who created the note
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the note was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the note was last updated
      attribute :time_updated, Shale::Type::Integer

      timestamps :time_created, :time_updated
    end
  end
end
