# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for board operations.
    #
    # Provides methods for creating, listing, updating, and deleting boards
    # and their lists (columns) via the Superthread API.
    class Boards < Base
      # Creates a new board in a space.
      #
      # @param workspace_id [String] the workspace identifier
      # @param space_id [String] the space identifier (maps to project_id in API)
      # @param title [String] the board title
      # @param params [Hash{Symbol => Object}] optional board parameters
      # @option params [String] :content the board description content
      # @option params [String] :icon the board icon identifier
      # @option params [String] :color the board color hex code
      # @option params [String] :layout the board layout type
      # @return [Superthread::Models::Board] the created board
      def create(workspace_id, space_id:, title:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = compact_params(title: title, project_id: space_id, **params)
        post_object("/#{ws}/boards", body: body,
          object_class: Models::Board, unwrap_key: :board)
      end

      # Lists all boards in a space.
      #
      # @param workspace_id [String] the workspace identifier
      # @param space_id [String] the space identifier to filter by
      # @param bookmarked [Boolean, nil] when true, returns only bookmarked boards
      # @param archived [Boolean, nil] when true, includes archived boards
      # @return [Superthread::Objects::Collection<Superthread::Models::Board>] the boards in the space
      def list(workspace_id, space_id:, bookmarked: nil, archived: nil)
        ws = safe_id("workspace_id", workspace_id)
        params = compact_params(project_id: space_id, bookmarked: bookmarked, archived: archived)
        get_collection("/#{ws}/boards", params: params,
          item_class: Models::Board, items_key: :boards)
      end

      # Gets a specific board with its lists and cards.
      #
      # @param workspace_id [String] the workspace identifier
      # @param board_id [String] the board identifier
      # @return [Superthread::Models::Board] the board with nested lists and cards
      def find(workspace_id, board_id)
        ws = safe_id("workspace_id", workspace_id)
        board = safe_id("board_id", board_id)
        get_object("/#{ws}/boards/#{board}",
          object_class: Models::Board, unwrap_key: :board)
      end

      # Updates a board's attributes.
      #
      # @param workspace_id [String] the workspace identifier
      # @param board_id [String] the board identifier
      # @param params [Hash{Symbol => Object}] the attributes to update
      # @option params [String] :title the new board title
      # @option params [String] :content the new board description
      # @option params [String] :icon the new board icon identifier
      # @option params [String] :color the new board color hex code
      # @option params [Boolean] :archived whether the board is archived
      # @return [Superthread::Models::Board] the updated board
      def update(workspace_id, board_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        board = safe_id("board_id", board_id)
        patch_object("/#{ws}/boards/#{board}", body: compact_params(**params),
          object_class: Models::Board, unwrap_key: :board)
      end

      # Duplicates a board to a destination space.
      #
      # @param workspace_id [String] the workspace identifier
      # @param board_id [String] the board identifier to duplicate
      # @param space_id [String] the destination space identifier
      # @param title [String, nil] the title for the duplicated board (defaults to original)
      # @param copy_cards [Boolean, nil] when true, copies all cards to the new board
      # @param create_missing_tags [Boolean, nil] when true, creates tags that do not exist in target space
      # @return [Superthread::Models::Board] the duplicated board
      def duplicate(workspace_id, board_id, space_id:, title: nil, copy_cards: nil, create_missing_tags: nil)
        ws = safe_id("workspace_id", workspace_id)
        board = safe_id("board_id", board_id)
        body = compact_params(project_id: space_id, title: title, copy_cards: copy_cards, create_missing_tags: create_missing_tags)
        post_object("/#{ws}/boards/#{board}/copy", body: body,
          object_class: Models::Board, unwrap_key: :board)
      end

      # Deletes a board permanently.
      #
      # @param workspace_id [String] the workspace identifier
      # @param board_id [String] the board identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def destroy(workspace_id, board_id)
        ws = safe_id("workspace_id", workspace_id)
        board = safe_id("board_id", board_id)
        http_delete("/#{ws}/boards/#{board}")
        success_response
      end

      # Creates a list (column) on a board.
      #
      # @param workspace_id [String] the workspace identifier
      # @param board_id [String] the board identifier to add the list to
      # @param title [String] the list title
      # @param params [Hash{Symbol => Object}] optional list parameters
      # @option params [String] :content the list description content
      # @option params [String] :icon the list icon identifier
      # @option params [String] :color the list color hex code
      # @option params [String] :behavior the list behavior type (e.g., "done")
      # @return [Superthread::Models::List] the created list
      def create_list(workspace_id, board_id:, title:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = compact_params(board_id: board_id, title: title, **params)
        post_object("/#{ws}/lists", body: body,
          object_class: Models::List, unwrap_key: :list)
      end

      # Updates a list's attributes.
      #
      # @param workspace_id [String] the workspace identifier
      # @param list_id [String] the list identifier
      # @param params [Hash{Symbol => Object}] the attributes to update
      # @option params [String] :title the new list title
      # @option params [String] :content the new list description
      # @option params [String] :icon the new list icon identifier
      # @option params [String] :color the new list color hex code
      # @option params [String] :behavior the new list behavior type
      # @return [Superthread::Models::List] the updated list
      def update_list(workspace_id, list_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        list = safe_id("list_id", list_id)
        patch_object("/#{ws}/lists/#{list}", body: compact_params(**params),
          object_class: Models::List, unwrap_key: :list)
      end

      # Deletes a list permanently.
      #
      # @param workspace_id [String] the workspace identifier
      # @param list_id [String] the list identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def delete_list(workspace_id, list_id)
        ws = safe_id("workspace_id", workspace_id)
        list = safe_id("list_id", list_id)
        http_delete("/#{ws}/lists/#{list}")
        success_response
      end
    end
  end
end
