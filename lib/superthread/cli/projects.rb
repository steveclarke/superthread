# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing Superthread projects (epics/roadmap items).
    #
    # Projects are high-level items on the roadmap that can contain multiple
    # cards. They have start/due dates, owners, and can be organized on boards.
    class Projects < Base
      # Kebab-case aliases for commands
      map "add-card" => :add_card,
        "remove-card" => :remove_card
      desc "list", "List all roadmap projects"
      # Lists all projects in the current workspace.
      #
      # @return [void]
      def list
        projects = client.projects.list(workspace_id)
        output_list projects, columns: %i[id title status], headers: {id: "PROJECT_ID"}
      end

      desc "get PROJECT", "Get project details"
      # Retrieves and displays details for a specific project.
      #
      # @param project_id [String] numeric ID or short code of the project/epic
      # @return [void]
      def get(project_id)
        handle_error do
          project = with_not_found("Project not found: '#{project_id}'. Use 'suth projects list' to see available projects.") do
            client.projects.find(workspace_id, project_id)
          end
          output_item project, fields: %i[id title status start_date due_date time_created time_updated],
            labels: {id: "Project ID"}
        end
      end

      desc "create", "Create a new project"
      option :title, type: :string, required: true, desc: "Project title"
      option :list, type: :string, required: true, aliases: "-l", desc: "Destination list (ID or name, requires --board)"
      option :board, type: :string, aliases: "-b", desc: "Board (helps resolve list name)"
      option :space, type: :string, aliases: "-s", desc: "Space (helps resolve board name)"
      option :content, type: :string, desc: "Project description"
      option :start_date, type: :numeric, desc: "Start date (Unix timestamp)"
      option :due_date, type: :numeric, desc: "Due date (Unix timestamp)"
      option :owner, type: :string, aliases: "-o", desc: "Owner (user ID, name, or email)"
      option :priority, type: :numeric, desc: "Priority level"
      # Creates a new project on a board list.
      #
      # @return [void]
      def create
        opts = symbolized_options(:title, :content, :start_date, :due_date, :priority)
        opts[:list_id] = resolve_list(options[:list])
        opts[:owner_id] = resolve_user(options[:owner]) if options[:owner]
        project = client.projects.create(workspace_id, **opts)
        output_item project, labels: {id: "Project ID"}
      end

      desc "update PROJECT", "Update a project"
      option :title, type: :string, desc: "New title"
      option :list, type: :string, aliases: "-l", desc: "Destination list (ID or name, requires --board)"
      option :board, type: :string, aliases: "-b", desc: "Board (helps resolve list name)"
      option :space, type: :string, aliases: "-s", desc: "Space (helps resolve board name)"
      option :owner, type: :string, aliases: "-o", desc: "New owner (user ID, name, or email)"
      option :start_date, type: :numeric, desc: "Start date"
      option :due_date, type: :numeric, desc: "Due date"
      option :priority, type: :numeric, desc: "Priority"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      # Updates an existing project's properties.
      #
      # @param project_id [String] numeric ID or short code of the project/epic
      # @return [void]
      def update(project_id)
        handle_error do
          opts = symbolized_options(:title, :start_date, :due_date, :priority, :archived)
          opts[:list_id] = resolve_list(options[:list]) if options[:list]
          opts[:owner_id] = resolve_user(options[:owner]) if options[:owner]
          project = with_not_found("Project not found: '#{project_id}'. Use 'suth projects list' to see available projects.") do
            client.projects.update(workspace_id, project_id, **opts)
          end
          output_item project, labels: {id: "Project ID"}
        end
      end

      desc "delete PROJECT", "Delete a project"
      # Deletes a project after confirmation.
      #
      # @param project_ref [String] project identifier (ID or name)
      # @return [void]
      def delete(project_ref)
        handle_error do
          project = with_not_found("Project not found: '#{project_ref}'. Use 'suth projects list' to see available projects.") do
            client.projects.find(workspace_id, project_ref)
          end
          confirming("Delete project '#{project.title}' (#{project.id})?") do
            client.projects.destroy(workspace_id, project.id)
            output_success "Project '#{project.title}' deleted"
          end
        end
      end

      desc "add_card PROJECT_ID CARD_ID", "Link a card to a project"
      # Links an existing card to a project.
      #
      # @param project_id [String] numeric ID or short code of the project/epic
      # @param card_id [String] unique identifier of the card to link
      # @return [void]
      def add_card(project_id, card_id)
        client.projects.add_card(workspace_id, project_id, card_id)
        output_success "Linked card #{card_id} to project #{project_id}"
      end

      desc "remove_card PROJECT_ID CARD_ID", "Remove a card from a project"
      # Removes a card's association from a project.
      #
      # @param project_id [String] numeric ID or short code of the project/epic
      # @param card_id [String] unique identifier of the card to unlink
      # @return [void]
      def remove_card(project_id, card_id)
        client.projects.remove_card(workspace_id, project_id, card_id)
        output_success "Removed card #{card_id} from project #{project_id}"
      end
    end
  end
end
