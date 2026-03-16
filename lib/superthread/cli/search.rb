# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for search operations.
    class Search < Base
      desc "query SEARCH_TERM", "Search across workspace"
      option :field, type: :string, enum: %w[title content], desc: "Field to search in"
      option :types, type: :string, desc: "Entity types to search (comma-separated: board,card,page,project,epic,note)"
      option :status, type: :string, desc: "Status filter (comma-separated, e.g., open,started)"
      option :space, type: :string, aliases: "-s", desc: "Space to filter by (ID or name)"
      option :include_archived, type: :boolean, desc: "Include archived items"
      option :grouped, type: :boolean, desc: "Group results by type"
      # Searches across all entities in the workspace.
      #
      # @param search_term [String] the text to search for
      # @return [void]
      def query(search_term)
        handle_error do
          types = options[:types]&.split(",")&.map(&:strip)
          statuses = options[:status]&.split(",")&.map(&:strip)
          results = client.search.query(
            workspace_id,
            query: search_term,
            field: options[:field],
            types: types,
            statuses: statuses,
            space_id: space_id,
            archived: options[:include_archived],
            grouped: options[:grouped],
            limit: effective_limit
          )
          output_list results, columns: %i[result_type id title], headers: {id: "ID"}
        end
      end

      private

      # Override Base#effective_limit for search-specific defaults.
      #
      # @return [Integer, nil] the limit (nil = unlimited when --limit 0)
      def effective_limit
        limit = options[:limit]
        return nil if limit == 0
        (limit.is_a?(Integer) && limit > 0) ? limit : 30
      end
    end
  end
end
