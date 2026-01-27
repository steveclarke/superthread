# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for note operations.
    #
    # Provides methods for listing, creating, and managing notes
    # (meeting notes, transcripts) via the Superthread API.
    class Notes < Base
      # Lists all notes in a workspace.
      #
      # @param workspace_id [String] the workspace identifier
      # @return [Superthread::Objects::Collection<Superthread::Models::Note>] the notes in the workspace
      def list(workspace_id)
        ws = safe_id("workspace_id", workspace_id)
        get_collection("/#{ws}/notes",
          item_class: Models::Note, items_key: :notes)
      end

      # Gets a specific note.
      #
      # @param workspace_id [String] the workspace identifier
      # @param note_id [String] the note identifier
      # @return [Superthread::Models::Note] the note with all attributes
      def find(workspace_id, note_id)
        ws = safe_id("workspace_id", workspace_id)
        note = safe_id("note_id", note_id)
        get_object("/#{ws}/notes/#{note}",
          object_class: Models::Note, unwrap_key: :note)
      end

      # Creates a new note.
      #
      # @param workspace_id [String] the workspace identifier
      # @param title [String] the note title
      # @param params [Hash{Symbol => Object}] optional note parameters
      # @option params [String] :transcript the meeting transcript content
      # @option params [Array<Hash{Symbol => Object}>] :transcripts multiple transcript segments
      # @option params [String] :user_notes user-added notes content
      # @return [Superthread::Models::Note] the created note
      def create(workspace_id, title:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = compact_params(title: title, **params)
        post_object("/#{ws}/notes", body: body,
          object_class: Models::Note, unwrap_key: :note)
      end

      # Deletes a note permanently.
      #
      # @param workspace_id [String] the workspace identifier
      # @param note_id [String] the note identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def destroy(workspace_id, note_id)
        ws = safe_id("workspace_id", workspace_id)
        note = safe_id("note_id", note_id)
        http_delete("/#{ws}/notes/#{note}")
        success_response
      end
    end
  end
end
