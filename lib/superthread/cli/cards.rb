# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for card operations.
    class Cards < Base
      # Kebab-case aliases for commands
      map "add-checklist" => :add_checklist,
        "edit-checklist" => :edit_checklist,
        "remove-checklist" => :remove_checklist,
        "add-item" => :add_item,
        "edit-item" => :edit_item,
        "remove-item" => :remove_item

      desc "list", "List cards on a board"
      option :board, type: :string, required: true, aliases: "-b", desc: "Board (ID or name)"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      option :list, type: :string, aliases: "-l", desc: "Filter by list (ID or name)"
      option :archived, type: :boolean, desc: "Include archived"
      def list
        handle_error do
          opts = symbolized_options(:archived)
          opts[:board_id] = board_id
          opts[:list_id] = resolve_list(options[:list]) if options[:list]
          cards = client.cards.list(workspace_id, **opts)
          output_list cards, columns: %i[id title priority list_title], headers: {list_title: "LIST"}
        end
      end

      desc "get CARD_ID", "Get card details"
      option :raw, type: :boolean, desc: "Show raw content without markdown rendering"
      option :no_content, type: :boolean, desc: "Hide content, show only metadata"
      def get(card_id)
        handle_error do
          card = client.cards.find(workspace_id, card_id)

          if json_output?
            fields = %i[id title status priority list_title board_title
              members start_date due_date time_created time_updated]
            fields.insert(2, :content) unless options[:no_content]
            output_item card, fields: fields
          else
            # Output metadata fields (status used for coloring list, not shown separately)
            output_item card,
              fields: %i[id title priority list_title board_title
                members start_date due_date time_created time_updated],
              labels: {list_title: "List", board_title: "Board"}

            # Render content separately with markdown formatting
            if !options[:no_content] && card.content && !card.content.empty?
              puts ""
              Ui.section "Content"
              if options[:raw]
                puts card.content
              else
                puts Ui.render_markdown(card.content)
              end
            end
          end
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
          raise Thor::Error, "Either --board or --sprint is required" unless options[:board] || options[:sprint]

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

      desc "delete CARD", "Delete a card"
      option :force, type: :boolean, aliases: "-f", desc: "Skip confirmation"
      def delete(card_ref)
        handle_error do
          card = client.cards.find(workspace_id, card_ref)
          confirming("Delete card '#{card.title}' (#{card.id})?") do
            client.cards.destroy(workspace_id, card.id)
            output_success "Card '#{card.title}' deleted"
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
          output_list cards, columns: %i[id title priority list_title], headers: {list_title: "LIST"}
        end
      end

      desc "assign CARD_ID USER", "Assign a user to a card"
      option :role, type: :string, default: "member", desc: "Member role"
      def assign(card_id, user_ref)
        handle_error do
          user_id = resolve_user(user_ref)
          client.cards.add_member(workspace_id, card_id, user_id: user_id, role: options[:role])
          Ui.success "Assigned #{user_ref} to card #{card_id}"
        end
      end

      desc "unassign CARD_ID USER", "Unassign a user from a card"
      def unassign(card_id, user_ref)
        handle_error do
          user_id = resolve_user(user_ref)
          client.cards.remove_member(workspace_id, card_id, user_id)
          Ui.success "Unassigned #{user_ref} from card #{card_id}"
        end
      end

      desc "link CARD_ID RELATED_CARD_ID", "Link two cards"
      option :type, type: :string, required: true, enum: %w[blocks blocked_by related duplicates],
        desc: "Relationship type"
      def link(card_id, related_card_id)
        handle_error do
          client.cards.add_related(
            workspace_id, card_id,
            related_card_id: related_card_id,
            relation_type: options[:type]
          )
          Ui.success "Linked #{card_id} -> #{related_card_id} (#{options[:type]})"
        end
      end

      desc "unlink CARD_ID LINKED_CARD_ID", "Remove card relationship"
      def unlink(card_id, linked_card_id)
        handle_error do
          client.cards.remove_related(workspace_id, card_id, linked_card_id)
          Ui.success "Unlinked #{card_id} from #{linked_card_id}"
        end
      end

      desc "add-checklist CARD_ID", "Create a checklist on a card"
      option :title, type: :string, required: true, desc: "Checklist title"
      def add_checklist(card_id)
        handle_error do
          checklist = client.cards.create_checklist(workspace_id, card_id, title: options[:title])
          output_item checklist, fields: %i[id title card_id time_created]
        end
      end

      desc "edit-checklist CARD_ID CHECKLIST_ID", "Update a checklist"
      option :title, type: :string, required: true, desc: "New checklist title"
      def edit_checklist(card_id, checklist_id)
        handle_error do
          checklist = client.cards.update_checklist(
            workspace_id, card_id, checklist_id,
            title: options[:title]
          )
          output_item checklist, fields: %i[id title card_id time_created]
        end
      end

      desc "remove-checklist CARD_ID CHECKLIST_ID", "Delete a checklist"
      option :force, type: :boolean, aliases: "-f", desc: "Skip confirmation"
      def remove_checklist(card_id, checklist_id)
        handle_error do
          card = client.cards.find(workspace_id, card_id)
          checklist = card.checklists&.find { |c| c.id == checklist_id }
          checklist_name = checklist&.title || checklist_id
          confirming("Delete checklist '#{checklist_name}' (#{checklist_id})?") do
            client.cards.delete_checklist(workspace_id, card_id, checklist_id)
            output_success "Checklist '#{checklist_name}' deleted"
          end
        end
      end

      desc "add-item CARD_ID CHECKLIST_ID", "Add item to a checklist"
      option :title, type: :string, required: true, desc: "Item title"
      option :checked, type: :boolean, default: false, desc: "Create as checked"
      def add_item(card_id, checklist_id)
        handle_error do
          item = client.cards.add_checklist_item(
            workspace_id, card_id, checklist_id,
            title: options[:title],
            checked: options[:checked]
          )
          output_item item, fields: %i[id title checked checklist_id]
        end
      end

      desc "edit-item CARD_ID CHECKLIST_ID ITEM_ID", "Update a checklist item"
      option :title, type: :string, desc: "New item title"
      option :checked, type: :boolean, desc: "Mark as checked/unchecked"
      def edit_item(card_id, checklist_id, item_id)
        handle_error do
          opts = symbolized_options(:title, :checked)
          item = client.cards.update_checklist_item(
            workspace_id, card_id, checklist_id, item_id,
            **opts
          )
          output_item item, fields: %i[id title checked checklist_id]
        end
      end

      desc "remove-item CARD_ID CHECKLIST_ID ITEM_ID", "Delete a checklist item"
      option :force, type: :boolean, aliases: "-f", desc: "Skip confirmation"
      def remove_item(card_id, checklist_id, item_id)
        handle_error do
          card = client.cards.find(workspace_id, card_id)
          checklist = card.checklists&.find { |c| c.id == checklist_id }
          item = checklist&.items&.find { |i| i.id == item_id }
          item_name = item&.title || item_id
          confirming("Delete checklist item '#{item_name}' (#{item_id})?") do
            client.cards.delete_checklist_item(workspace_id, card_id, checklist_id, item_id)
            output_success "Checklist item '#{item_name}' deleted"
          end
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

      desc "tag CARD_ID TAGS", "Add tags to card (comma-separated IDs or names)"
      def tag(card_id, tag_refs)
        handle_error do
          ids = tag_refs.split(",").map { |ref| resolve_tag(ref.strip) }
          client.cards.add_tags(workspace_id, card_id, tag_ids: ids)
          Ui.success "Added #{ids.count} tag(s) to card #{card_id}"
        end
      end

      desc "untag CARD_ID TAG", "Remove tag from card"
      def untag(card_id, tag_ref)
        handle_error do
          tag_id = resolve_tag(tag_ref)
          client.cards.remove_tag(workspace_id, card_id, tag_id)
          Ui.success "Removed tag #{tag_ref} from card #{card_id}"
        end
      end
    end
  end
end
