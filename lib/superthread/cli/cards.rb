# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for card operations.
    class Cards < Base
      desc 'get CARD_ID', 'Get card details'
      def get(card_id)
        card = client.cards.find(workspace_id, card_id)
        output_item card, fields: %i[id title status priority list_title board_title
                                     owner_id start_date due_date time_created time_updated]
      end

      desc 'create', 'Create a new card'
      option :title, type: :string, required: true, desc: 'Card title'
      option :list_id, type: :string, required: true, desc: 'List ID'
      option :board_id, type: :string, desc: 'Board ID (required unless sprint_id)'
      option :sprint_id, type: :string, desc: 'Sprint ID (required unless board_id)'
      option :content, type: :string, desc: 'Card content (HTML)'
      option :project_id, type: :string, desc: 'Project ID'
      option :start_date, type: :numeric, desc: 'Start date (Unix timestamp)'
      option :due_date, type: :numeric, desc: 'Due date (Unix timestamp)'
      option :priority, type: :numeric, desc: 'Priority level (1=urgent, 4=low)'
      option :parent_card_id, type: :string, desc: 'Parent card ID'
      option :epic_id, type: :string, desc: 'Epic ID'
      option :owner_id, type: :string, desc: 'Owner user ID'
      def create
        card = client.cards.create(
          workspace_id,
          **symbolized_options(:title, :list_id, :board_id, :sprint_id, :content,
                               :project_id, :start_date, :due_date, :priority,
                               :parent_card_id, :epic_id, :owner_id)
        )
        output_item card
      end

      desc 'update CARD_ID', 'Update a card'
      option :title, type: :string, desc: 'New title'
      option :list_id, type: :string, desc: 'Move to list'
      option :board_id, type: :string, desc: 'Move to board'
      option :priority, type: :numeric, desc: 'Priority level (1=urgent, 4=low)'
      option :archived, type: :boolean, desc: 'Archive/unarchive'
      def update(card_id)
        card = client.cards.update(
          workspace_id,
          card_id,
          **symbolized_options(:title, :list_id, :board_id, :priority, :archived)
        )
        output_item card
      end

      desc 'delete CARD_ID', 'Delete a card'
      def delete(card_id)
        client.cards.destroy(workspace_id, card_id)
        output_success "Card #{card_id} deleted"
      end

      desc 'duplicate CARD_ID', 'Duplicate a card'
      option :title, type: :string, desc: 'Title for the copy'
      def duplicate(card_id)
        card = client.cards.duplicate(workspace_id, card_id, **symbolized_options(:title))
        output_item card
      end

      desc 'assigned USER_ID', 'Get cards assigned to a user'
      option :board_id, type: :string, desc: 'Filter by board'
      option :project_id, type: :string, desc: 'Filter by project'
      option :archived, type: :boolean, desc: 'Include archived'
      def assigned(user_id)
        cards = client.cards.assigned(
          workspace_id,
          user_id: user_id,
          **symbolized_options(:board_id, :project_id, :archived)
        )
        output_list cards, columns: %i[id title status priority list_title]
      end

      desc 'add_member CARD_ID USER_ID', 'Add member to card'
      option :role, type: :string, default: 'member', desc: 'Member role'
      def add_member(card_id, user_id)
        client.cards.add_member(workspace_id, card_id, user_id: user_id, role: options[:role])
        output_success "Added #{user_id} to card #{card_id}"
      end

      desc 'remove_member CARD_ID USER_ID', 'Remove member from card'
      def remove_member(card_id, user_id)
        client.cards.remove_member(workspace_id, card_id, user_id)
        output_success "Removed #{user_id} from card #{card_id}"
      end

      desc 'add_related CARD_ID RELATED_CARD_ID', 'Link two cards'
      option :type, type: :string, required: true, enum: %w[blocks blocked_by related duplicates],
                    desc: 'Relationship type'
      def add_related(card_id, related_card_id)
        client.cards.add_related(
          workspace_id, card_id,
          related_card_id: related_card_id,
          relation_type: options[:type]
        )
        output_success "Linked card #{card_id} -> #{related_card_id} (#{options[:type]})"
      end

      desc 'remove_related CARD_ID LINKED_CARD_ID', 'Remove card relationship'
      def remove_related(card_id, linked_card_id)
        client.cards.remove_related(workspace_id, card_id, linked_card_id)
        output_success "Removed link between #{card_id} and #{linked_card_id}"
      end

      desc 'checklist_create CARD_ID', 'Create a checklist on a card'
      option :title, type: :string, required: true, desc: 'Checklist title'
      def checklist_create(card_id)
        checklist = client.cards.create_checklist(workspace_id, card_id, title: options[:title])
        output_item checklist, fields: %i[id title card_id time_created]
      end

      desc 'checklist_add_item CARD_ID CHECKLIST_ID', 'Add item to checklist'
      option :title, type: :string, required: true, desc: 'Item title'
      option :checked, type: :boolean, default: false, desc: 'Create as checked'
      def checklist_add_item(card_id, checklist_id)
        item = client.cards.add_checklist_item(
          workspace_id, card_id, checklist_id,
          title: options[:title],
          checked: options[:checked]
        )
        output_item item, fields: %i[id title checked checklist_id]
      end

      desc 'tags', 'Get available tags'
      option :project_id, type: :string, desc: 'Filter by project'
      option :all, type: :boolean, desc: 'Get all tags'
      def tags
        tags = client.cards.tags(workspace_id, **symbolized_options(:project_id, :all))
        output_list tags, columns: %i[id name color total_cards]
      end

      desc 'add_tags CARD_ID TAG_IDS', 'Add tags to card (comma-separated IDs)'
      def add_tags(card_id, tag_ids)
        ids = tag_ids.split(',').map(&:strip)
        client.cards.add_tags(workspace_id, card_id, tag_ids: ids)
        output_success "Added #{ids.count} tag(s) to card #{card_id}"
      end

      desc 'remove_tag CARD_ID TAG_ID', 'Remove tag from card'
      def remove_tag(card_id, tag_id)
        client.cards.remove_tag(workspace_id, card_id, tag_id)
        output_success "Removed tag #{tag_id} from card #{card_id}"
      end
    end
  end
end
