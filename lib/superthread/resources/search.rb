# frozen_string_literal: true

module Superthread
  module Resources
    class Search < Base
      # Searches across workspace entities.
      # API: GET /:workspace/search
      #
      # @param workspace_id [String] Workspace ID
      # @param query [String] Search query
      # @param params [Hash] Optional search parameters
      # @option params [String] :field Field to search (title, content)
      # @option params [Array<String>] :types Entity types to include (board, card, page, etc.)
      # @option params [Array<String>] :statuses Status filters
      # @option params [String] :space_id Space ID to filter by
      # @option params [Boolean] :archived Include archived entities
      # @option params [Boolean] :grouped Group results by type
      # @option params [String] :cursor Pagination cursor
      # @return [Hash] Search results
      def query(workspace_id, query:, **params)
        ws = safe_id("workspace_id", workspace_id)
        search_params = build_params(q: query, project_id: params[:space_id], **params.except(:space_id))
        get("/#{ws}/search", params: search_params)
      end
    end
  end
end
