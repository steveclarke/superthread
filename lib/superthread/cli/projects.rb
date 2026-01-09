# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for project (epic/roadmap item) operations.
    class Projects < Base
      desc 'list', 'List all roadmap projects'
      def list
        projects = client.projects.list(workspace_id)
        output_list projects, columns: %i[id title status]
      end

      desc 'get PROJECT_ID', 'Get project details'
      def get(project_id)
        project = client.projects.find(workspace_id, project_id)
        output_item project, fields: %i[id title status start_date due_date time_created time_updated]
      end

      desc 'create', 'Create a new project'
      option :title, type: :string, required: true, desc: 'Project title'
      option :list_id, type: :string, required: true, desc: 'List ID'
      option :content, type: :string, desc: 'Project description'
      option :start_date, type: :numeric, desc: 'Start date (Unix timestamp)'
      option :due_date, type: :numeric, desc: 'Due date (Unix timestamp)'
      option :owner_id, type: :string, desc: 'Owner user ID'
      option :priority, type: :numeric, desc: 'Priority level'
      def create
        project = client.projects.create(workspace_id,
                                         **symbolized_options(:title, :list_id, :content, :start_date, :due_date,
                                                              :owner_id, :priority))
        output_item project
      end

      desc 'update PROJECT_ID', 'Update a project'
      option :title, type: :string, desc: 'New title'
      option :list_id, type: :string, desc: 'Move to list'
      option :owner_id, type: :string, desc: 'New owner'
      option :start_date, type: :numeric, desc: 'Start date'
      option :due_date, type: :numeric, desc: 'Due date'
      option :priority, type: :numeric, desc: 'Priority'
      option :archived, type: :boolean, desc: 'Archive/unarchive'
      def update(project_id)
        project = client.projects.update(workspace_id, project_id,
                                         **symbolized_options(:title, :list_id, :owner_id, :start_date, :due_date, :priority, :archived))
        output_item project
      end

      desc 'delete PROJECT_ID', 'Delete a project'
      def delete(project_id)
        client.projects.destroy(workspace_id, project_id)
        output_success "Project #{project_id} deleted"
      end

      desc 'add_card PROJECT_ID CARD_ID', 'Link a card to a project'
      def add_card(project_id, card_id)
        client.projects.add_card(workspace_id, project_id, card_id)
        output_success "Linked card #{card_id} to project #{project_id}"
      end

      desc 'remove_card PROJECT_ID CARD_ID', 'Remove a card from a project'
      def remove_card(project_id, card_id)
        client.projects.remove_card(workspace_id, project_id, card_id)
        output_success "Removed card #{card_id} from project #{project_id}"
      end
    end
  end
end
