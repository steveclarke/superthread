# frozen_string_literal: true

module Superthread
  module Cli
    class Notes < Base
      desc "list", "List all notes"
      def list
        output client.notes.list(workspace_id)
      end

      desc "get NOTE_ID", "Get note details"
      def get(note_id)
        output client.notes.get(workspace_id, note_id)
      end

      desc "create", "Create a new note"
      option :title, type: :string, required: true, desc: "Note title"
      option :transcript, type: :string, desc: "Transcript content"
      option :user_notes, type: :string, desc: "User notes"
      option :is_public, type: :boolean, desc: "Make note public"
      def create
        output client.notes.create(
          workspace_id,
          title: options[:title],
          transcript: options[:transcript],
          user_notes: options[:user_notes],
          is_public: options[:is_public]
        )
      end

      desc "delete NOTE_ID", "Delete a note"
      def delete(note_id)
        output client.notes.delete(workspace_id, note_id)
      end
    end
  end
end
