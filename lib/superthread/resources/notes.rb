# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for note operations.
    class Notes < Base
      # Lists all notes in a workspace.
      # API: GET /:workspace/notes
      #
      # @param workspace_id [String] Workspace ID
      # @return [Superthread::Objects::Collection<Note>] List of notes
      def list(workspace_id)
        ws = safe_id("workspace_id", workspace_id)
        get_collection("/#{ws}/notes",
          item_class: Models::Note, items_key: :notes)
      end

      # Gets a specific note.
      # API: GET /:workspace/notes/:note
      #
      # @param workspace_id [String] Workspace ID
      # @param note_id [String] Note ID
      # @return [Superthread::Models::Note] Note details
      def find(workspace_id, note_id)
        ws = safe_id("workspace_id", workspace_id)
        note = safe_id("note_id", note_id)
        get_object("/#{ws}/notes/#{note}",
          object_class: Models::Note, unwrap_key: :note)
      end

      # Creates a new note.
      # API: POST /:workspace/notes
      #
      # @param workspace_id [String] Workspace ID
      # @param title [String] Note title
      # @param params [Hash] Optional parameters (transcript, transcripts, user_notes, etc.)
      # @return [Superthread::Models::Note] Created note
      def create(workspace_id, title:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = compact_params(title: title, **params)
        post_object("/#{ws}/notes", body: body,
          object_class: Models::Note, unwrap_key: :note)
      end

      # Deletes a note.
      # API: DELETE /:workspace/notes/:note
      #
      # @param workspace_id [String] Workspace ID
      # @param note_id [String] Note ID
      # @return [Superthread::Object] Success response
      def destroy(workspace_id, note_id)
        ws = safe_id("workspace_id", workspace_id)
        note = safe_id("note_id", note_id)
        http_delete("/#{ws}/notes/#{note}")
        success_response
      end
    end
  end
end
