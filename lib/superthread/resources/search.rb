# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for search operations.
    #
    # Provides methods for searching across workspace entities
    # (cards, pages, boards, etc.) via the Superthread API.
    class Search < Base
      # Safety cap on pagination requests to prevent runaway loops.
      MAX_PAGES = 100

      # Searches across workspace entities.
      #
      # Follows pagination cursors automatically. When limit is provided,
      # stops after accumulating that many results.
      #
      # @param workspace_id [String] the workspace identifier
      # @param query [String] the search query string
      # @param limit [Integer, nil] max results to return (nil = no limit)
      # @param params [Hash{Symbol => Object}] optional search parameters
      # @option params [String] :field the field to search (title, content)
      # @option params [Array<String>] :types entity types to include (board, card, page, etc.)
      # @option params [Array<String>] :statuses status values to filter by
      # @option params [String] :space_id the space identifier to filter by
      # @option params [Boolean] :archived when true, includes archived entities
      # @option params [Boolean] :grouped when true, groups results by type (default: false)
      # @return [Superthread::Objects::Collection] the search results
      def query(workspace_id, query:, limit: nil, **params)
        ws = safe_id("workspace_id", workspace_id)
        grouped = params.fetch(:grouped, false)
        all_results = []
        cursor = nil
        pages = 0

        loop do
          search_params = compact_params(
            query: query,
            project_id: params[:space_id],
            grouped: grouped,
            cursor: cursor,
            **params.except(:space_id, :grouped)
          )
          response = http_get("/#{ws}/search", params: search_params)

          results = (response[:results] || []).map do |item|
            result_type, data = item.first
            data.merge(result_type: result_type.to_s)
          end
          all_results.concat(results)

          cursor = response[:cursor]
          pages += 1
          break if cursor.nil? || cursor.empty?
          break if limit && all_results.size >= limit
          break if pages >= MAX_PAGES
        end

        all_results = all_results.first(limit) if limit
        Objects::Collection.from_response(all_results)
      end
    end
  end
end
