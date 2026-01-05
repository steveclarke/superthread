# frozen_string_literal: true

module Superthread
  module Resources
    class Notes < Base
      # Lists all notes in a workspace.
      # API: GET /:workspace/notes
      #
      # @param workspace_id [String] Workspace ID
      # @return [Hash] List of notes
      def list(workspace_id)
        ws = safe_id("workspace_id", workspace_id)
        get("/#{ws}/notes")
      end

      # Gets a specific note.
      # API: GET /:workspace/notes/:note
      #
      # @param workspace_id [String] Workspace ID
      # @param note_id [String] Note ID
      # @return [Hash] Note details
      def get(workspace_id, note_id)
        ws = safe_id("workspace_id", workspace_id)
        note = safe_id("note_id", note_id)
        get("/#{ws}/notes/#{note}")
      end

      # Creates a new note.
      # API: POST /:workspace/notes
      #
      # @param workspace_id [String] Workspace ID
      # @param title [String] Note title
      # @param params [Hash] Optional parameters (transcript, transcripts, user_notes, etc.)
      # @return [Hash] Created note
      def create(workspace_id, title:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = build_params(title: title, **params)
        post("/#{ws}/notes", body: body)
      end

      # Deletes a note.
      # API: DELETE /:workspace/notes/:note
      #
      # @param workspace_id [String] Workspace ID
      # @param note_id [String] Note ID
      # @return [Hash] Success response
      def delete(workspace_id, note_id)
        ws = safe_id("workspace_id", workspace_id)
        note = safe_id("note_id", note_id)
        delete("/#{ws}/notes/#{note}")
      end
    end
  end
end
