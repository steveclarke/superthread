# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for project (epic/roadmap item) operations.
    class Projects < Base
      # Lists all roadmap projects (epics) in a workspace.
      # API: GET /:workspace/epics
      #
      # @param workspace_id [String] Workspace ID
      # @return [Superthread::Objects::Collection<Project>] List of projects
      def list(workspace_id)
        ws = safe_id('workspace_id', workspace_id)
        get_collection("/#{ws}/epics",
                       item_class: Objects::Project, items_key: :epics)
      end

      # Gets a specific project.
      # API: GET /:workspace/epics/:project
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Project ID (maps to epic_id)
      # @return [Superthread::Objects::Project] Project details
      def find(workspace_id, project_id)
        ws = safe_id('workspace_id', workspace_id)
        proj = safe_id('project_id', project_id)
        get_object("/#{ws}/epics/#{proj}",
                   object_class: Objects::Project, unwrap_key: :epic)
      end

      # Creates a new project.
      # API: POST /:workspace/epics
      #
      # @param workspace_id [String] Workspace ID
      # @param title [String] Project title
      # @param list_id [String] List ID
      # @param params [Hash] Optional parameters
      # @return [Superthread::Objects::Project] Created project
      def create(workspace_id, title:, list_id:, **params)
        ws = safe_id('workspace_id', workspace_id)
        body = compact_params(title: title, list_id: list_id, **params)
        post_object("/#{ws}/epics", body: body,
                                    object_class: Objects::Project, unwrap_key: :epic)
      end

      # Updates a project.
      # API: PATCH /:workspace/epics/:project
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Project ID
      # @param params [Hash] Update parameters
      # @return [Superthread::Objects::Project] Updated project
      def update(workspace_id, project_id, **params)
        ws = safe_id('workspace_id', workspace_id)
        proj = safe_id('project_id', project_id)
        patch_object("/#{ws}/epics/#{proj}", body: compact_params(**params),
                                             object_class: Objects::Project, unwrap_key: :epic)
      end

      # Deletes a project.
      # API: DELETE /:workspace/epics/:project
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Project ID
      # @return [Superthread::Object] Success response
      def destroy(workspace_id, project_id)
        ws = safe_id('workspace_id', workspace_id)
        proj = safe_id('project_id', project_id)
        http_delete("/#{ws}/epics/#{proj}")
        success_response
      end

      # Links a card to a project.
      # API: POST /:workspace/epics/:project/cards/:card
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Project ID
      # @param card_id [String] Card ID to link
      # @return [Superthread::Object] Result
      def add_card(workspace_id, project_id, card_id)
        ws = safe_id('workspace_id', workspace_id)
        proj = safe_id('project_id', project_id)
        card = safe_id('card_id', card_id)
        post_object("/#{ws}/epics/#{proj}/cards/#{card}")
      end

      # Removes a card from a project.
      # API: DELETE /:workspace/epics/:project/cards/:card
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Project ID
      # @param card_id [String] Card ID to remove
      # @return [Superthread::Object] Success response
      def remove_card(workspace_id, project_id, card_id)
        ws = safe_id('workspace_id', workspace_id)
        proj = safe_id('project_id', project_id)
        card = safe_id('card_id', card_id)
        http_delete("/#{ws}/epics/#{proj}/cards/#{card}")
        success_response
      end
    end
  end
end
