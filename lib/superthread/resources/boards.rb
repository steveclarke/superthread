# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for board operations.
    class Boards < Base
      # Creates a new board.
      # API: POST /:workspace/boards
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID (maps to project_id in API)
      # @param title [String] Board title
      # @param params [Hash] Optional parameters (content, icon, color, layout)
      # @return [Superthread::Objects::Board] Created board
      def create(workspace_id, space_id:, title:, **params)
        ws = safe_id('workspace_id', workspace_id)
        body = compact_params(title: title, project_id: space_id, **params)
        post_object("/#{ws}/boards", body: body,
                                     object_class: Objects::Board, unwrap_key: :board)
      end

      # Lists all boards in a space.
      # API: GET /:workspace/boards
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @param bookmarked [Boolean] Filter by bookmarked status
      # @param archived [Boolean] Include archived boards
      # @return [Superthread::Objects::Collection<Board>] List of boards
      def list(workspace_id, space_id:, bookmarked: nil, archived: nil)
        ws = safe_id('workspace_id', workspace_id)
        params = compact_params(project_id: space_id, bookmarked: bookmarked, archived: archived)
        get_collection("/#{ws}/boards", params: params,
                                        item_class: Objects::Board, items_key: :boards)
      end

      # Gets a specific board with lists and cards.
      # API: GET /:workspace/boards/:board
      #
      # @param workspace_id [String] Workspace ID
      # @param board_id [String] Board ID
      # @return [Superthread::Objects::Board] Board details
      def find(workspace_id, board_id)
        ws = safe_id('workspace_id', workspace_id)
        board = safe_id('board_id', board_id)
        get_object("/#{ws}/boards/#{board}",
                   object_class: Objects::Board, unwrap_key: :board)
      end

      # Updates a board.
      # API: PATCH /:workspace/boards/:board
      #
      # @param workspace_id [String] Workspace ID
      # @param board_id [String] Board ID
      # @param params [Hash] Update parameters
      # @return [Superthread::Objects::Board] Updated board
      def update(workspace_id, board_id, **params)
        ws = safe_id('workspace_id', workspace_id)
        board = safe_id('board_id', board_id)
        patch_object("/#{ws}/boards/#{board}", body: compact_params(**params),
                                               object_class: Objects::Board, unwrap_key: :board)
      end

      # Duplicates a board.
      # API: POST /:workspace/boards/:board/copy
      #
      # @param workspace_id [String] Workspace ID
      # @param board_id [String] Board ID to duplicate
      # @param title [String] Optional new title
      # @param space_id [String] Optional destination space
      # @return [Superthread::Objects::Board] Duplicated board
      def duplicate(workspace_id, board_id, title: nil, space_id: nil)
        ws = safe_id('workspace_id', workspace_id)
        board = safe_id('board_id', board_id)
        body = compact_params(title: title, project_id: space_id)
        post_object("/#{ws}/boards/#{board}/copy", body: body,
                                                   object_class: Objects::Board, unwrap_key: :board)
      end

      # Deletes a board.
      # API: DELETE /:workspace/boards/:board
      #
      # @param workspace_id [String] Workspace ID
      # @param board_id [String] Board ID
      # @return [Superthread::Object] Success response
      def destroy(workspace_id, board_id)
        ws = safe_id('workspace_id', workspace_id)
        board = safe_id('board_id', board_id)
        http_delete("/#{ws}/boards/#{board}")
        success_response
      end

      # Creates a list (column) on a board.
      # API: POST /:workspace/lists
      #
      # @param workspace_id [String] Workspace ID
      # @param board_id [String] Board ID
      # @param title [String] List title
      # @param params [Hash] Optional parameters (content, icon, color, behavior)
      # @return [Superthread::Objects::List] Created list
      def create_list(workspace_id, board_id:, title:, **params)
        ws = safe_id('workspace_id', workspace_id)
        body = compact_params(board_id: board_id, title: title, **params)
        post_object("/#{ws}/lists", body: body,
                                    object_class: Objects::List, unwrap_key: :list)
      end

      # Updates a list.
      # API: PATCH /:workspace/lists/:list
      #
      # @param workspace_id [String] Workspace ID
      # @param list_id [String] List ID
      # @param params [Hash] Update parameters
      # @return [Superthread::Objects::List] Updated list
      def update_list(workspace_id, list_id, **params)
        ws = safe_id('workspace_id', workspace_id)
        list = safe_id('list_id', list_id)
        patch_object("/#{ws}/lists/#{list}", body: compact_params(**params),
                                             object_class: Objects::List, unwrap_key: :list)
      end

      # Deletes a list.
      # API: DELETE /:workspace/lists/:list
      #
      # @param workspace_id [String] Workspace ID
      # @param list_id [String] List ID
      # @return [Superthread::Object] Success response
      def delete_list(workspace_id, list_id)
        ws = safe_id('workspace_id', workspace_id)
        list = safe_id('list_id', list_id)
        http_delete("/#{ws}/lists/#{list}")
        success_response
      end
    end
  end
end
