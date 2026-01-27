# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for project (epic/roadmap item) operations.
    #
    # Provides methods for creating, updating, and managing projects
    # (epics) and their linked cards via the Superthread API.
    class Projects < Base
      # Lists all roadmap projects (epics) in a workspace.
      #
      # @param workspace_id [String] the workspace identifier
      # @return [Superthread::Objects::Collection<Superthread::Models::Project>] the projects in the workspace
      # @note The API returns epics nested within lists (status columns).
      #   This method flattens them into a single collection.
      def list(workspace_id)
        ws = safe_id("workspace_id", workspace_id)
        data = http_get("/#{ws}/epics")

        # Epics are nested inside each list - flatten them
        epics = (data[:lists] || []).flat_map { |list| list[:epics] || [] }

        Superthread::Objects::Collection.from_response(
          {epics: epics},
          key: :epics,
          item_class: Models::Project
        )
      end

      # Gets a specific project.
      #
      # @param workspace_id [String] the workspace identifier
      # @param project_id [String] the project identifier (maps to epic_id in API)
      # @return [Superthread::Models::Project] the project with all attributes
      def find(workspace_id, project_id)
        ws = safe_id("workspace_id", workspace_id)
        proj = safe_id("project_id", project_id)
        get_object("/#{ws}/epics/#{proj}",
          object_class: Models::Project, unwrap_key: :epic)
      end

      # Creates a new project (epic) on the roadmap.
      #
      # @param workspace_id [String] the workspace identifier
      # @param title [String] the project title
      # @param list_id [String] the list identifier (status column) for the project
      # @param params [Hash{Symbol => Object}] optional project parameters
      # @option params [String] :content the project description content
      # @option params [Integer] :start_date the start date as Unix timestamp
      # @option params [Integer] :due_date the due date as Unix timestamp
      # @return [Superthread::Models::Project] the created project
      def create(workspace_id, title:, list_id:, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = compact_params(title: title, list_id: list_id, **params)
        post_object("/#{ws}/epics", body: body,
          object_class: Models::Project, unwrap_key: :epic)
      end

      # Updates a project's attributes.
      #
      # @param workspace_id [String] the workspace identifier
      # @param project_id [String] the project identifier
      # @param params [Hash{Symbol => Object}] the attributes to update
      # @option params [String] :title the new project title
      # @option params [String] :content the new project description
      # @option params [String] :list_id the new list identifier (status column)
      # @option params [Integer] :start_date the new start date as Unix timestamp
      # @option params [Integer] :due_date the new due date as Unix timestamp
      # @return [Superthread::Models::Project] the updated project
      def update(workspace_id, project_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        proj = safe_id("project_id", project_id)
        patch_object("/#{ws}/epics/#{proj}", body: compact_params(**params),
          object_class: Models::Project, unwrap_key: :epic)
      end

      # Deletes a project permanently.
      #
      # @param workspace_id [String] the workspace identifier
      # @param project_id [String] the project identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def destroy(workspace_id, project_id)
        ws = safe_id("workspace_id", workspace_id)
        proj = safe_id("project_id", project_id)
        http_delete("/#{ws}/epics/#{proj}")
        success_response
      end

      # Links a card to a project (epic).
      #
      # @param workspace_id [String] the workspace identifier
      # @param project_id [String] the project identifier
      # @param card_id [String] the card identifier to link
      # @return [Superthread::Object] the link result
      def add_card(workspace_id, project_id, card_id)
        ws = safe_id("workspace_id", workspace_id)
        proj = safe_id("project_id", project_id)
        card = safe_id("card_id", card_id)
        post_object("/#{ws}/epics/#{proj}/cards/#{card}")
      end

      # Removes a card from a project (epic).
      #
      # @param workspace_id [String] the workspace identifier
      # @param project_id [String] the project identifier
      # @param card_id [String] the card identifier to remove
      # @return [Superthread::Object] a response object with success: true
      def remove_card(workspace_id, project_id, card_id)
        ws = safe_id("workspace_id", workspace_id)
        proj = safe_id("project_id", project_id)
        card = safe_id("card_id", card_id)
        http_delete("/#{ws}/epics/#{proj}/cards/#{card}")
        success_response
      end
    end
  end
end
