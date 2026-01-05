# frozen_string_literal: true

module Superthread
  module Cli
    class Cards < Base
      desc "get CARD_ID", "Get card details"
      def get(card_id)
        output client.cards.get(workspace_id, card_id)
      end

      desc "create", "Create a new card"
      option :title, type: :string, required: true, desc: "Card title"
      option :list_id, type: :string, required: true, desc: "List ID"
      option :board_id, type: :string, desc: "Board ID (required unless sprint_id)"
      option :sprint_id, type: :string, desc: "Sprint ID (required unless board_id)"
      option :content, type: :string, desc: "Card content (HTML)"
      option :project_id, type: :string, desc: "Project ID"
      option :start_date, type: :numeric, desc: "Start date (Unix timestamp)"
      option :due_date, type: :numeric, desc: "Due date (Unix timestamp)"
      option :priority, type: :numeric, desc: "Priority level"
      option :parent_card_id, type: :string, desc: "Parent card ID"
      option :epic_id, type: :string, desc: "Epic ID"
      option :owner_id, type: :string, desc: "Owner user ID"
      def create
        result = client.cards.create(
          workspace_id,
          **options.slice(:title, :list_id, :board_id, :sprint_id, :content,
                          :project_id, :start_date, :due_date, :priority,
                          :parent_card_id, :epic_id, :owner_id).transform_keys(&:to_sym)
        )
        output result
      end

      desc "update CARD_ID", "Update a card"
      option :title, type: :string, desc: "New title"
      option :list_id, type: :string, desc: "Move to list"
      option :board_id, type: :string, desc: "Move to board"
      option :priority, type: :numeric, desc: "Priority level"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      def update(card_id)
        result = client.cards.update(
          workspace_id,
          card_id,
          **options.slice(:title, :list_id, :board_id, :priority, :archived).transform_keys(&:to_sym)
        )
        output result
      end

      desc "delete CARD_ID", "Delete a card"
      def delete(card_id)
        output client.cards.delete(workspace_id, card_id)
      end

      desc "duplicate CARD_ID", "Duplicate a card"
      option :title, type: :string, desc: "Title for the copy"
      def duplicate(card_id)
        result = client.cards.duplicate(workspace_id, card_id, title: options[:title])
        output result
      end

      desc "assigned USER_ID", "Get cards assigned to a user"
      option :board_id, type: :string, desc: "Filter by board"
      option :project_id, type: :string, desc: "Filter by project"
      option :archived, type: :boolean, desc: "Include archived"
      def assigned(user_id)
        result = client.cards.assigned(
          workspace_id,
          user_id: user_id,
          **options.slice(:board_id, :project_id, :archived).transform_keys(&:to_sym)
        )
        output result
      end

      desc "add_member CARD_ID USER_ID", "Add member to card"
      option :role, type: :string, default: "member", desc: "Member role"
      def add_member(card_id, user_id)
        output client.cards.add_member(workspace_id, card_id, user_id: user_id, role: options[:role])
      end

      desc "remove_member CARD_ID USER_ID", "Remove member from card"
      def remove_member(card_id, user_id)
        output client.cards.remove_member(workspace_id, card_id, user_id)
      end

      desc "add_related CARD_ID RELATED_CARD_ID", "Link two cards"
      option :type, type: :string, required: true, enum: %w[blocks blocked_by related duplicates],
             desc: "Relationship type"
      def add_related(card_id, related_card_id)
        output client.cards.add_related(
          workspace_id, card_id,
          related_card_id: related_card_id,
          relation_type: options[:type]
        )
      end

      desc "remove_related CARD_ID LINKED_CARD_ID", "Remove card relationship"
      def remove_related(card_id, linked_card_id)
        output client.cards.remove_related(workspace_id, card_id, linked_card_id)
      end

      desc "checklist_create CARD_ID", "Create a checklist on a card"
      option :title, type: :string, required: true, desc: "Checklist title"
      def checklist_create(card_id)
        output client.cards.create_checklist(workspace_id, card_id, title: options[:title])
      end

      desc "checklist_add_item CARD_ID CHECKLIST_ID", "Add item to checklist"
      option :title, type: :string, required: true, desc: "Item title"
      option :checked, type: :boolean, default: false, desc: "Create as checked"
      def checklist_add_item(card_id, checklist_id)
        output client.cards.add_checklist_item(
          workspace_id, card_id, checklist_id,
          title: options[:title],
          checked: options[:checked]
        )
      end

      desc "tags", "Get available tags"
      option :project_id, type: :string, desc: "Filter by project"
      option :all, type: :boolean, desc: "Get all tags"
      def tags
        output client.cards.tags(workspace_id, project_id: options[:project_id], all: options[:all])
      end

      desc "add_tags CARD_ID TAG_IDS", "Add tags to card (comma-separated IDs)"
      def add_tags(card_id, tag_ids)
        ids = tag_ids.split(",").map(&:strip)
        output client.cards.add_tags(workspace_id, card_id, tag_ids: ids)
      end

      desc "remove_tag CARD_ID TAG_ID", "Remove tag from card"
      def remove_tag(card_id, tag_id)
        output client.cards.remove_tag(workspace_id, card_id, tag_id)
      end
    end
  end
end
