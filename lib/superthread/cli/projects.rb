# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for project (epic/roadmap item) operations.
    class Projects < Base
      desc "list", "List all roadmap projects"
      def list
        projects = client.projects.list(workspace_id)
        output_list projects, columns: %i[id title status]
      end

      desc "get PROJECT_ID", "Get project details"
      option :open, type: :boolean, aliases: "-o", desc: "Open in web browser"
      def get(project_id)
        handle_error do
          project = client.projects.find(workspace_id, project_id)
          output_item project, fields: %i[id title status start_date due_date time_created time_updated]

          open_in_browser(:project, project_id)
        end
      end

      desc "create", "Create a new project"
      option :title, type: :string, required: true, desc: "Project title"
      option :list, type: :string, required: true, aliases: "-l", desc: "List (ID or name, requires --board)"
      option :board, type: :string, aliases: "-b", desc: "Board (ID or name) - helps resolve list by name"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      option :content, type: :string, desc: "Project description"
      option :start_date, type: :numeric, desc: "Start date (Unix timestamp)"
      option :due_date, type: :numeric, desc: "Due date (Unix timestamp)"
      option :owner, type: :string, aliases: "-o", desc: "Owner (user ID, name, or email)"
      option :priority, type: :numeric, desc: "Priority level"
      def create
        opts = symbolized_options(:title, :content, :start_date, :due_date, :priority)
        opts[:list_id] = resolve_list(options[:list])
        opts[:owner_id] = resolve_user(options[:owner]) if options[:owner]
        project = client.projects.create(workspace_id, **opts)
        output_item project
      end

      desc "update PROJECT_ID", "Update a project"
      option :title, type: :string, desc: "New title"
      option :list, type: :string, aliases: "-l", desc: "Move to list (ID or name, requires --board)"
      option :board, type: :string, aliases: "-b", desc: "Board (ID or name) - helps resolve list by name"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      option :owner, type: :string, aliases: "-o", desc: "New owner (user ID, name, or email)"
      option :start_date, type: :numeric, desc: "Start date"
      option :due_date, type: :numeric, desc: "Due date"
      option :priority, type: :numeric, desc: "Priority"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      def update(project_id)
        opts = symbolized_options(:title, :start_date, :due_date, :priority, :archived)
        opts[:list_id] = resolve_list(options[:list]) if options[:list]
        opts[:owner_id] = resolve_user(options[:owner]) if options[:owner]
        project = client.projects.update(workspace_id, project_id, **opts)
        output_item project
      end

      desc "delete PROJECT", "Delete a project"
      def delete(project_ref)
        handle_error do
          project = client.projects.find(workspace_id, project_ref)
          confirming("Delete project '#{project.title}' (#{project.id})?") do
            client.projects.destroy(workspace_id, project.id)
            output_success "Project '#{project.title}' deleted"
          end
        end
      end

      desc "add_card PROJECT_ID CARD_ID", "Link a card to a project"
      def add_card(project_id, card_id)
        client.projects.add_card(workspace_id, project_id, card_id)
        output_success "Linked card #{card_id} to project #{project_id}"
      end

      desc "remove_card PROJECT_ID CARD_ID", "Remove a card from a project"
      def remove_card(project_id, card_id)
        client.projects.remove_card(workspace_id, project_id, card_id)
        output_success "Removed card #{card_id} from project #{project_id}"
      end
    end
  end
end
