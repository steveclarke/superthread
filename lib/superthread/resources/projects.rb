# frozen_string_literal: true

module Superthread
  module Resources
    class Projects < Base
      # Lists all roadmap projects (epics) in a workspace.
      # API: GET /:workspace/epics
      #
      # @param workspace_id [String] Workspace ID
      # @return [Hash] List of projects
      def list(workspace_id)
        ws = safe_id("workspace_id", workspace_id)
        get("/#{ws}/epics")
      end

      # Gets a specific project.
      # API: GET /:workspace/epics/:project
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Project ID (maps to epic_id)
      # @return [Hash] Project details
      def get(workspace_id, project_id)
        ws = safe_id("workspace_id", workspace_id)
        proj = safe_id("project_id", project_id)
        get("/#{ws}/epics/#{proj}")
      end

      # Creates a new project.
      # API: POST /:workspace/epics
      #
      # @param workspace_id [String] Workspace ID
      # @param title [String] Project title
      # @param list_id [String] List ID
      # @param params [Hash] Optional parameters
      # @return [Hash] Created project
      def create(workspace_id, title:, list_id:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = build_params(title: title, list_id: list_id, **params)
        post("/#{ws}/epics", body: body)
      end

      # Updates a project.
      # API: PATCH /:workspace/epics/:project
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Project ID
      # @param params [Hash] Update parameters
      # @return [Hash] Updated project
      def update(workspace_id, project_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        proj = safe_id("project_id", project_id)
        patch("/#{ws}/epics/#{proj}", body: build_params(**params))
      end

      # Deletes a project.
      # API: DELETE /:workspace/epics/:project
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Project ID
      # @return [Hash] Success response
      def delete(workspace_id, project_id)
        ws = safe_id("workspace_id", workspace_id)
        proj = safe_id("project_id", project_id)
        delete("/#{ws}/epics/#{proj}")
      end

      # Links a card to a project.
      # API: POST /:workspace/epics/:project/cards/:card (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Project ID
      # @param card_id [String] Card ID to link
      # @return [Hash] Result
      def add_card(workspace_id, project_id, card_id)
        ws = safe_id("workspace_id", workspace_id)
        proj = safe_id("project_id", project_id)
        card = safe_id("card_id", card_id)
        post("/#{ws}/epics/#{proj}/cards/#{card}")
      end

      # Removes a card from a project.
      # API: DELETE /:workspace/epics/:project/cards/:card (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Project ID
      # @param card_id [String] Card ID to remove
      # @return [Hash] Success response
      def remove_card(workspace_id, project_id, card_id)
        ws = safe_id("workspace_id", workspace_id)
        proj = safe_id("project_id", project_id)
        card = safe_id("card_id", card_id)
        delete("/#{ws}/epics/#{proj}/cards/#{card}")
      end
    end
  end
end
