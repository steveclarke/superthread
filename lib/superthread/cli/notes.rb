# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for note operations.
    class Notes < Base
      desc 'list', 'List all notes'
      def list
        notes = client.notes.list(workspace_id)
        output_list notes, columns: %i[id title time_created]
      end

      desc 'get NOTE_ID', 'Get note details'
      def get(note_id)
        note = client.notes.find(workspace_id, note_id)
        output_item note, fields: %i[id title content time_created time_updated]
      end

      desc 'create', 'Create a new note'
      option :title, type: :string, required: true, desc: 'Note title'
      option :transcript, type: :string, desc: 'Transcript content'
      option :user_notes, type: :string, desc: 'User notes'
      option :is_public, type: :boolean, desc: 'Make note public'
      def create
        note = client.notes.create(workspace_id, **symbolized_options(:title, :transcript, :user_notes, :is_public))
        output_item note
      end

      desc 'delete NOTE_ID', 'Delete a note'
      def delete(note_id)
        client.notes.destroy(workspace_id, note_id)
        output_success "Note #{note_id} deleted"
      end
    end
  end
end
