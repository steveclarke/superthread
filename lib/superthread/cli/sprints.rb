# frozen_string_literal: true

module Superthread
  module Cli
    class Sprints < Base
      desc "list", "List all sprints in a space"
      option :space_id, type: :string, required: true, desc: "Space ID"
      def list
        output client.sprints.list(workspace_id, space_id: options[:space_id])
      end

      desc "get SPRINT_ID", "Get sprint details"
      option :space_id, type: :string, required: true, desc: "Space ID"
      def get(sprint_id)
        output client.sprints.get(workspace_id, sprint_id, space_id: options[:space_id])
      end
    end
  end
end
