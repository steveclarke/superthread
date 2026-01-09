# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for sprint operations.
    class Sprints < Base
      # Lists all sprints in a space.
      # API: GET /:workspace/sprints
      #
      # @param workspace_id [String] Workspace ID
      # @param space_id [String] Space ID
      # @return [Superthread::Objects::Collection<Sprint>] List of sprints
      def list(workspace_id, space_id:)
        ws = safe_id('workspace_id', workspace_id)
        params = compact_params(project_id: space_id)
        get_collection("/#{ws}/sprints", params: params,
                                         item_class: Objects::Sprint, items_key: :sprints)
      end

      # Gets a specific sprint.
      # API: GET /:workspace/sprints/:sprint
      #
      # @param workspace_id [String] Workspace ID
      # @param sprint_id [String] Sprint ID
      # @param space_id [String] Space ID (required for this endpoint)
      # @return [Superthread::Objects::Sprint] Sprint details with available lists
      def find(workspace_id, sprint_id, space_id:)
        ws = safe_id('workspace_id', workspace_id)
        sprint = safe_id('sprint_id', sprint_id)
        params = compact_params(project_id: space_id)
        get_object("/#{ws}/sprints/#{sprint}", params: params,
                                               object_class: Objects::Sprint, unwrap_key: :sprint)
      end
    end
  end
end
