# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for sprint operations.
    class Sprints < Base
      desc "list", "List all sprints in a space"
      option :space, type: :string, required: true, aliases: "-s", desc: "Space (ID or name)"
      # Lists all sprints in a specified space.
      #
      # @return [void]
      def list
        sprints = client.sprints.list(workspace_id, space_id: space_id)
        output_list sprints, columns: %i[id title start_date], headers: {id: "SPRINT_ID"}
      end

      desc "get SPRINT", "Get sprint details"
      option :space, type: :string, required: true, aliases: "-s", desc: "Space (ID or name)"
      # Displays detailed information about a specific sprint.
      #
      # @param sprint_id [String] the unique identifier of the sprint to retrieve
      # @return [void]
      def get(sprint_id)
        handle_error do
          sprint = client.sprints.find(workspace_id, sprint_id, space_id: space_id)
          output_item sprint, fields: %i[id title start_date time_created time_updated], labels: {
            id: "Sprint ID",
            start_date: "Start Date",
            time_created: "Time Created",
            time_updated: "Time Updated"
          }
        end
      end
    end
  end
end
