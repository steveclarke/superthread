# frozen_string_literal: true

module Superthread
  module Cli
    class Projects < Base
      desc "list", "List all roadmap projects"
      def list
        output client.projects.list(workspace_id)
      end

      desc "get PROJECT_ID", "Get project details"
      def get(project_id)
        output client.projects.get(workspace_id, project_id)
      end

      desc "create", "Create a new project"
      option :title, type: :string, required: true, desc: "Project title"
      option :list_id, type: :string, required: true, desc: "List ID"
      option :content, type: :string, desc: "Project description"
      option :start_date, type: :numeric, desc: "Start date (Unix timestamp)"
      option :due_date, type: :numeric, desc: "Due date (Unix timestamp)"
      option :owner_id, type: :string, desc: "Owner user ID"
      option :priority, type: :numeric, desc: "Priority level"
      def create
        output client.projects.create(
          workspace_id,
          **options.slice(:title, :list_id, :content, :start_date, :due_date,
            :owner_id, :priority).transform_keys(&:to_sym)
        )
      end

      desc "update PROJECT_ID", "Update a project"
      option :title, type: :string, desc: "New title"
      option :list_id, type: :string, desc: "Move to list"
      option :owner_id, type: :string, desc: "New owner"
      option :start_date, type: :numeric, desc: "Start date"
      option :due_date, type: :numeric, desc: "Due date"
      option :priority, type: :numeric, desc: "Priority"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      def update(project_id)
        output client.projects.update(
          workspace_id,
          project_id,
          **options.slice(:title, :list_id, :owner_id, :start_date, :due_date,
            :priority, :archived).transform_keys(&:to_sym)
        )
      end

      desc "delete PROJECT_ID", "Delete a project"
      def delete(project_id)
        output client.projects.delete(workspace_id, project_id)
      end

      desc "add_card PROJECT_ID CARD_ID", "Link a card to a project"
      def add_card(project_id, card_id)
        output client.projects.add_card(workspace_id, project_id, card_id)
      end

      desc "remove_card PROJECT_ID CARD_ID", "Remove a card from a project"
      def remove_card(project_id, card_id)
        output client.projects.remove_card(workspace_id, project_id, card_id)
      end
    end
  end
end
