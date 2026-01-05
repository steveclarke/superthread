# frozen_string_literal: true

module Superthread
  module Resources
    class Boards < Base
      # Creates a new board.
      # API: POST /:workspace/boards
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID (maps to project_id in API)
      # @param title [String] Board title
      # @param params [Hash] Optional parameters (content, icon, color, layout)
      # @return [Hash] Created board
      def create(workspace_id, space_id:, title:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = build_params(title: title, project_id: space_id, **params)
        http_post("/#{ws}/boards", body: body)
      end

      # Lists all boards in a space.
      # API: GET /:workspace/boards
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @param bookmarked [Boolean] Filter by bookmarked status
      # @param archived [Boolean] Include archived boards
      # @return [Hash] List of boards
      def list(workspace_id, space_id:, bookmarked: nil, archived: nil)
        ws = safe_id("workspace_id", workspace_id)
        params = build_params(project_id: space_id, bookmarked: bookmarked, archived: archived)
        http_get("/#{ws}/boards", params: params)
      end

      # Gets a specific board with lists and cards.
      # API: GET /:workspace/boards/:board
      #
      # @param workspace_id [String] Workspace ID
      # @param board_id [String] Board ID
      # @return [Hash] Board details
      def find(workspace_id, board_id)
        ws = safe_id("workspace_id", workspace_id)
        board = safe_id("board_id", board_id)
        http_get("/#{ws}/boards/#{board}")
      end

      # Updates a board.
      # API: PATCH /:workspace/boards/:board
      #
      # @param workspace_id [String] Workspace ID
      # @param board_id [String] Board ID
      # @param params [Hash] Update parameters
      # @return [Hash] Updated board
      def update(workspace_id, board_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        board = safe_id("board_id", board_id)
        http_patch("/#{ws}/boards/#{board}", body: build_params(**params))
      end

      # Duplicates a board.
      # API: POST /:workspace/boards/:board/copy
      #
      # @param workspace_id [String] Workspace ID
      # @param board_id [String] Board ID to duplicate
      # @param title [String] Optional new title
      # @param space_id [String] Optional destination space
      # @return [Hash] Duplicated board
      def duplicate(workspace_id, board_id, title: nil, space_id: nil)
        ws = safe_id("workspace_id", workspace_id)
        board = safe_id("board_id", board_id)
        body = build_params(title: title, project_id: space_id)
        http_post("/#{ws}/boards/#{board}/copy", body: body)
      end

      # Deletes a board.
      # API: DELETE /:workspace/boards/:board
      #
      # @param workspace_id [String] Workspace ID
      # @param board_id [String] Board ID
      # @return [Hash] Success response
      def destroy(workspace_id, board_id)
        ws = safe_id("workspace_id", workspace_id)
        board = safe_id("board_id", board_id)
        http_delete("/#{ws}/boards/#{board}")
      end

      # Creates a list (column) on a board.
      # API: POST /:workspace/lists
      #
      # @param workspace_id [String] Workspace ID
      # @param board_id [String] Board ID
      # @param title [String] List title
      # @param params [Hash] Optional parameters (content, icon, color, behavior)
      # @return [Hash] Created list
      def create_list(workspace_id, board_id:, title:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = build_params(board_id: board_id, title: title, **params)
        http_post("/#{ws}/lists", body: body)
      end

      # Updates a list.
      # API: PATCH /:workspace/lists/:list
      #
      # @param workspace_id [String] Workspace ID
      # @param list_id [String] List ID
      # @param params [Hash] Update parameters
      # @return [Hash] Updated list
      def update_list(workspace_id, list_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        list = safe_id("list_id", list_id)
        http_patch("/#{ws}/lists/#{list}", body: build_params(**params))
      end

      # Deletes a list.
      # API: DELETE /:workspace/lists/:list
      #
      # @param workspace_id [String] Workspace ID
      # @param list_id [String] List ID
      # @return [Hash] Success response
      def delete_list(workspace_id, list_id)
        ws = safe_id("workspace_id", workspace_id)
        list = safe_id("list_id", list_id)
        http_delete("/#{ws}/lists/#{list}")
      end
    end
  end
end
