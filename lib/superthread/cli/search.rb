# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for search operations.
    class Search < Base
      desc 'query SEARCH_TERM', 'Search across workspace'
      option :field, type: :string, enum: %w[title content], desc: 'Field to search'
      option :types, type: :string, desc: 'Entity types (comma-separated: board,card,page,project,epic,note)'
      option :space_id, type: :string, desc: 'Filter by space'
      option :archived, type: :boolean, desc: 'Include archived'
      option :grouped, type: :boolean, desc: 'Group results by type'
      def query(search_term)
        types = options[:types]&.split(',')&.map(&:strip)
        results = client.search.query(
          workspace_id,
          query: search_term,
          field: options[:field],
          types: types,
          space_id: options[:space_id],
          archived: options[:archived],
          grouped: options[:grouped]
        )
        output_list results
      end
    end
  end
end
