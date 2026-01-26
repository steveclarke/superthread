# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for sprint operations.
    #
    # Provides methods for listing and retrieving sprints
    # via the Superthread API.
    class Sprints < Base
      # Lists all sprints in a space.
      #
      # @param workspace_id [String] the workspace identifier
      # @param space_id [String] the space identifier to list sprints from
      # @return [Superthread::Objects::Collection<Superthread::Models::Sprint>] the sprints in the space
      def list(workspace_id, space_id:)
        ws = safe_id("workspace_id", workspace_id)
        params = compact_params(project_id: space_id)
        get_collection("/#{ws}/sprints", params: params,
          item_class: Models::Sprint, items_key: :sprints)
      end

      # Gets a specific sprint with its available lists.
      #
      # @param workspace_id [String] the workspace identifier
      # @param sprint_id [String] the sprint identifier
      # @param space_id [String] the space identifier (required by the API)
      # @return [Superthread::Models::Sprint] the sprint with available lists
      def find(workspace_id, sprint_id, space_id:)
        ws = safe_id("workspace_id", workspace_id)
        sprint = safe_id("sprint_id", sprint_id)
        params = compact_params(project_id: space_id)
        get_object("/#{ws}/sprints/#{sprint}", params: params,
          object_class: Models::Sprint, unwrap_key: :sprint)
      end
    end
  end
end
