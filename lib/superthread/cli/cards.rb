# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for card operations.
    class Cards < Base
      desc "get CARD_ID", "Get card details"
      def get(card_id)
        handle_error do
          card = client.cards.find(workspace_id, card_id)
          output_item card, fields: %i[id title status priority list_title board_title
            owner_id start_date due_date time_created time_updated]
        end
      end

      desc "create", "Create a new card"
      option :title, type: :string, required: true, desc: "Card title"
      option :list, type: :string, required: true, aliases: "-l", desc: "List (ID or name, requires --board)"
      option :board, type: :string, aliases: "-b", desc: "Board (ID or name, required unless --sprint)"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      option :sprint, type: :string, desc: "Sprint (ID, required unless --board)"
      option :content, type: :string, desc: "Card content (HTML)"
      option :project, type: :string, desc: "Project (ID)"
      option :start_date, type: :numeric, desc: "Start date (Unix timestamp)"
      option :due_date, type: :numeric, desc: "Due date (Unix timestamp)"
      option :priority, type: :numeric, desc: "Priority level (1=urgent, 4=low)"
      option :parent_card, type: :string, desc: "Parent card ID"
      option :epic, type: :string, desc: "Epic ID"
      option :owner, type: :string, aliases: "-o", desc: "Owner (user ID, name, or email)"
      def create
        handle_error do
          opts = symbolized_options(:title, :content, :start_date, :due_date, :priority)
          opts[:list_id] = resolve_list(options[:list])
          opts[:board_id] = board_id if options[:board]
          opts[:sprint_id] = options[:sprint] if options[:sprint]
          opts[:project_id] = options[:project] if options[:project]
          opts[:parent_card_id] = options[:parent_card] if options[:parent_card]
          opts[:epic_id] = options[:epic] if options[:epic]
          opts[:owner_id] = resolve_user(options[:owner]) if options[:owner]
          card = client.cards.create(workspace_id, **opts)
          output_item card
        end
      end

      desc "update CARD_ID", "Update a card"
      option :title, type: :string, desc: "New title"
      option :list, type: :string, aliases: "-l", desc: "Move to list (ID or name, requires --board)"
      option :board, type: :string, aliases: "-b", desc: "Move to board (ID or name)"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      option :priority, type: :numeric, desc: "Priority level (1=urgent, 4=low)"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      def update(card_id)
        handle_error do
          opts = symbolized_options(:title, :priority, :archived)
          opts[:list_id] = resolve_list(options[:list]) if options[:list]
          opts[:board_id] = board_id if options[:board]
          card = client.cards.update(workspace_id, card_id, **opts)
          output_item card
        end
      end

      desc "delete CARD_ID", "Delete a card"
      option :force, type: :boolean, aliases: "-f", desc: "Skip confirmation"
      def delete(card_id)
        handle_error do
          confirming("Delete card #{card_id}?") do
            client.cards.destroy(workspace_id, card_id)
            Ui.success "Card #{card_id} deleted"
          end
        end
      end

      desc "duplicate CARD_ID", "Duplicate a card"
      option :title, type: :string, desc: "Title for the copy"
      def duplicate(card_id)
        handle_error do
          card = client.cards.duplicate(workspace_id, card_id, **symbolized_options(:title))
          output_item card
        end
      end

      desc "assigned USER", "Get cards assigned to a user"
      option :board, type: :string, aliases: "-b", desc: "Filter by board (ID or name)"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      option :project, type: :string, desc: "Filter by project (ID)"
      option :archived, type: :boolean, desc: "Include archived"
      def assigned(user_ref)
        handle_error do
          opts = symbolized_options(:archived)
          opts[:user_id] = resolve_user(user_ref)
          opts[:board_id] = board_id if options[:board]
          opts[:project_id] = options[:project] if options[:project]
          cards = client.cards.assigned(workspace_id, **opts)
          output_list cards, columns: %i[id title status priority list_title]
        end
      end

      desc "add_member CARD_ID USER", "Add member to card"
      option :role, type: :string, default: "member", desc: "Member role"
      def add_member(card_id, user_ref)
        handle_error do
          user_id = resolve_user(user_ref)
          client.cards.add_member(workspace_id, card_id, user_id: user_id, role: options[:role])
          Ui.success "Added #{user_ref} to card #{card_id}"
        end
      end

      desc "remove_member CARD_ID USER", "Remove member from card"
      def remove_member(card_id, user_ref)
        handle_error do
          user_id = resolve_user(user_ref)
          client.cards.remove_member(workspace_id, card_id, user_id)
          Ui.success "Removed #{user_ref} from card #{card_id}"
        end
      end

      desc "add_related CARD_ID RELATED_CARD_ID", "Link two cards"
      option :type, type: :string, required: true, enum: %w[blocks blocked_by related duplicates],
        desc: "Relationship type"
      def add_related(card_id, related_card_id)
        handle_error do
          client.cards.add_related(
            workspace_id, card_id,
            related_card_id: related_card_id,
            relation_type: options[:type]
          )
          Ui.success "Linked card #{card_id} -> #{related_card_id} (#{options[:type]})"
        end
      end

      desc "remove_related CARD_ID LINKED_CARD_ID", "Remove card relationship"
      def remove_related(card_id, linked_card_id)
        handle_error do
          client.cards.remove_related(workspace_id, card_id, linked_card_id)
          Ui.success "Removed link between #{card_id} and #{linked_card_id}"
        end
      end

      desc "checklist_create CARD_ID", "Create a checklist on a card"
      option :title, type: :string, required: true, desc: "Checklist title"
      def checklist_create(card_id)
        handle_error do
          checklist = client.cards.create_checklist(workspace_id, card_id, title: options[:title])
          output_item checklist, fields: %i[id title card_id time_created]
        end
      end

      desc "checklist_add_item CARD_ID CHECKLIST_ID", "Add item to checklist"
      option :title, type: :string, required: true, desc: "Item title"
      option :checked, type: :boolean, default: false, desc: "Create as checked"
      def checklist_add_item(card_id, checklist_id)
        handle_error do
          item = client.cards.add_checklist_item(
            workspace_id, card_id, checklist_id,
            title: options[:title],
            checked: options[:checked]
          )
          output_item item, fields: %i[id title checked checklist_id]
        end
      end

      desc "tags", "Get available tags"
      option :project, type: :string, desc: "Filter by project (ID)"
      option :all, type: :boolean, desc: "Get all tags"
      def tags
        handle_error do
          opts = symbolized_options(:all)
          opts[:project_id] = options[:project] if options[:project]
          tags = client.cards.tags(workspace_id, **opts)
          output_list tags, columns: %i[id name color total_cards]
        end
      end

      desc "add_tags CARD_ID TAGS", "Add tags to card (comma-separated IDs or names)"
      def add_tags(card_id, tag_refs)
        handle_error do
          ids = tag_refs.split(",").map { |ref| resolve_tag(ref.strip) }
          client.cards.add_tags(workspace_id, card_id, tag_ids: ids)
          Ui.success "Added #{ids.count} tag(s) to card #{card_id}"
        end
      end

      desc "remove_tag CARD_ID TAG", "Remove tag from card"
      def remove_tag(card_id, tag_ref)
        handle_error do
          tag_id = resolve_tag(tag_ref)
          client.cards.remove_tag(workspace_id, card_id, tag_id)
          Ui.success "Removed tag #{tag_ref} from card #{card_id}"
        end
      end
    end
  end
end
