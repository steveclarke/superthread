# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for sprint operations.
    class Sprints < Base
      desc 'list', 'List all sprints in a space'
      option :space_id, type: :string, required: true, desc: 'Space ID'
      def list
        sprints = client.sprints.list(workspace_id, space_id: options[:space_id])
        output_list sprints, columns: %i[id title status start_date due_date]
      end

      desc 'get SPRINT_ID', 'Get sprint details'
      option :space_id, type: :string, required: true, desc: 'Space ID'
      def get(sprint_id)
        sprint = client.sprints.find(workspace_id, sprint_id, space_id: options[:space_id])
        output_item sprint, fields: %i[id title status start_date due_date time_created time_updated]
      end
    end
  end
end
