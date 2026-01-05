# frozen_string_literal: true

module Superthread
  module Resources
    class Sprints < Base
      # Lists all sprints in a space.
      # API: GET /:workspace/sprints
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @return [Hash] List of sprints
      def list(workspace_id, space_id:)
        ws = safe_id("workspace_id", workspace_id)
        params = build_params(project_id: space_id)
        http_get("/#{ws}/sprints", params: params)
      end

      # Gets a specific sprint.
      # API: GET /:workspace/sprints/:sprint (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param sprint_id [String] Sprint ID
      # @param space_id [String] Space ID (required for this endpoint)
      # @return [Hash] Sprint details with available lists
      def find(workspace_id, sprint_id, space_id:)
        ws = safe_id("workspace_id", workspace_id)
        sprint = safe_id("sprint_id", sprint_id)
        params = build_params(project_id: space_id)
        http_get("/#{ws}/sprints/#{sprint}", params: params)
      end
    end
  end
end
