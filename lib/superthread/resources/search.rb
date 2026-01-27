# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for search operations.
    #
    # Provides methods for searching across workspace entities
    # (cards, pages, boards, etc.) via the Superthread API.
    class Search < Base
      # Searches across workspace entities.
      #
      # @param workspace_id [String] the workspace identifier
      # @param query [String] the search query string
      # @param params [Hash{Symbol => Object}] optional search parameters
      # @option params [String] :field the field to search (title, content)
      # @option params [Array<String>] :types entity types to include (board, card, page, etc.)
      # @option params [Array<String>] :statuses status values to filter by
      # @option params [String] :space_id the space identifier to filter by
      # @option params [Boolean] :archived when true, includes archived entities
      # @option params [Boolean] :grouped when true, groups results by type (default: false)
      # @option params [String] :cursor the pagination cursor for next page
      # @return [Superthread::Objects::Collection] the search results
      def query(workspace_id, query:, **params)
        ws = safe_id("workspace_id", workspace_id)
        # Default grouped to false so results come in a flat array
        # Use || instead of fetch because CLI may pass grouped: nil explicitly
        grouped = params[:grouped].nil? ? false : params[:grouped]
        search_params = compact_params(
          query: query,
          project_id: params[:space_id],
          grouped: grouped,
          **params.except(:space_id, :grouped)
        )
        response = http_get("/#{ws}/search", params: search_params)

        # Unwrap results - each item is {"card": {...}} or {"board": {...}}, etc.
        results = (response[:results] || []).map do |item|
          result_type, data = item.first
          data.merge(result_type: result_type.to_s)
        end

        Objects::Collection.from_response(results)
      end
    end
  end
end
