# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing Superthread notes.
    #
    # Notes are standalone content items that can contain transcripts
    # and user annotations. They can be made public for sharing.
    class Notes < Base
      desc "list", "List all notes"
      # Lists all notes in the current workspace.
      #
      # @return [void]
      def list
        notes = client.notes.list(workspace_id)
        output_list notes, columns: %i[id title time_created]
      end

      desc "get NOTE_ID", "Get note details"
      # Retrieves and displays details for a specific note.
      #
      # @param note_id [String] numeric ID of the note to retrieve
      # @return [void]
      def get(note_id)
        handle_error do
          note = client.notes.find(workspace_id, note_id)
          output_item note, fields: %i[id title content time_created time_updated]
        end
      end

      desc "create", "Create a new note"
      option :title, type: :string, required: true, desc: "Note title"
      option :transcript, type: :string, desc: "Transcript content"
      option :user_notes, type: :string, desc: "User notes"
      option :is_public, type: :boolean, desc: "Make note public"
      # Creates a new note in the current workspace.
      #
      # @return [void]
      def create
        note = client.notes.create(workspace_id, **symbolized_options(:title, :transcript, :user_notes, :is_public))
        output_item note
      end

      desc "delete NOTE", "Delete a note"
      # Deletes a note after confirmation.
      #
      # @param note_ref [String] note identifier (ID or name)
      # @return [void]
      def delete(note_ref)
        handle_error do
          note = client.notes.find(workspace_id, note_ref)
          confirming("Delete note '#{note.title}' (#{note.id})?") do
            client.notes.destroy(workspace_id, note.id)
            output_success "Note '#{note.title}' deleted"
          end
        end
      end
    end
  end
end
