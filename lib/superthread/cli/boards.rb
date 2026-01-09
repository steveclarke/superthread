# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for board operations.
    class Boards < Base
      desc 'list', 'List all boards in a space'
      option :space_id, type: :string, required: true, desc: 'Space ID'
      option :bookmarked, type: :boolean, desc: 'Filter by bookmarked'
      option :archived, type: :boolean, desc: 'Include archived'
      def list
        boards = client.boards.list(workspace_id, **symbolized_options(:space_id, :bookmarked, :archived))
        output_list boards, columns: %i[id title]
      end

      desc 'get BOARD_ID', 'Get board details'
      def get(board_id)
        board = client.boards.find(workspace_id, board_id)
        output_item board, fields: %i[id title description space_id time_created time_updated]
      end

      desc 'create', 'Create a new board'
      option :space_id, type: :string, required: true, desc: 'Space ID'
      option :title, type: :string, required: true, desc: 'Board title'
      option :content, type: :string, desc: 'Board description'
      option :icon, type: :string, desc: 'Board icon'
      option :color, type: :string, desc: 'Board color'
      def create
        board = client.boards.create(workspace_id, **symbolized_options(:space_id, :title, :content, :icon, :color))
        output_item board
      end

      desc 'update BOARD_ID', 'Update a board'
      option :title, type: :string, desc: 'New title'
      option :content, type: :string, desc: 'New description'
      option :icon, type: :string, desc: 'New icon'
      option :color, type: :string, desc: 'New color'
      option :archived, type: :boolean, desc: 'Archive/unarchive'
      def update(board_id)
        board = client.boards.update(workspace_id, board_id,
                                     **symbolized_options(:title, :content, :icon, :color, :archived))
        output_item board
      end

      desc 'duplicate BOARD_ID', 'Duplicate a board'
      option :title, type: :string, desc: 'Title for the copy'
      option :space_id, type: :string, desc: 'Destination space'
      def duplicate(board_id)
        board = client.boards.duplicate(workspace_id, board_id, **symbolized_options(:title, :space_id))
        output_item board
      end

      desc 'delete BOARD_ID', 'Delete a board'
      def delete(board_id)
        client.boards.destroy(workspace_id, board_id)
        output_success "Board #{board_id} deleted"
      end

      desc 'list_create', 'Create a list on a board'
      option :board_id, type: :string, required: true, desc: 'Board ID'
      option :title, type: :string, required: true, desc: 'List title'
      option :content, type: :string, desc: 'List description'
      option :icon, type: :string, desc: 'List icon'
      option :color, type: :string, desc: 'List color'
      def list_create
        list = client.boards.create_list(workspace_id, **symbolized_options(:board_id, :title, :content, :icon, :color))
        output_item list, fields: %i[id title color board_id]
      end

      desc 'list_update LIST_ID', 'Update a list'
      option :title, type: :string, desc: 'New title'
      option :content, type: :string, desc: 'New description'
      option :icon, type: :string, desc: 'New icon'
      option :color, type: :string, desc: 'New color'
      def list_update(list_id)
        list = client.boards.update_list(workspace_id, list_id, **symbolized_options(:title, :content, :icon, :color))
        output_item list
      end

      desc 'list_delete LIST_ID', 'Delete a list'
      def list_delete(list_id)
        client.boards.delete_list(workspace_id, list_id)
        output_success "List #{list_id} deleted"
      end
    end
  end
end
