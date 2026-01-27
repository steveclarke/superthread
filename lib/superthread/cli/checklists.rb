# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing card checklists.
    #
    # Checklists are task lists attached to cards with trackable items.
    # This class provides commands to create, update, and delete checklists
    # as well as manage checklist items.
    class Checklists < Base
      # Kebab-case aliases for commands
      map "add-item" => :add_item,
        "update-item" => :update_item,
        "remove-item" => :remove_item

      desc "list", "List all checklists on a card"
      option :card, type: :string, required: true, aliases: "-c", desc: "Parent card ID"
      # List all checklists on a specified card.
      #
      # @return [void]
      def list
        handle_error do
          card = client.cards.find(workspace_id, options[:card])
          if card.checklists.nil? || card.checklists.empty?
            say "No checklists found on this card.", :yellow
          else
            output_list card.checklists, columns: %i[id title], headers: {id: "CHECKLIST_ID"}
          end
        end
      end

      desc "get CHECKLIST", "Get checklist details"
      option :card, type: :string, required: true, aliases: "-c", desc: "Parent card ID"
      # Display detailed information about a specific checklist.
      #
      # @param checklist_id [String] the unique identifier of the checklist
      # @return [void]
      def get(checklist_id)
        handle_error do
          card = client.cards.find(workspace_id, options[:card])
          checklist = card.checklists&.find { |c| c.id == checklist_id }
          raise Thor::Error, "Checklist not found: #{checklist_id}" unless checklist

          if json_output?
            output_item checklist, fields: %i[id title card_id items time_created], labels: {id: "Checklist ID"}
          else
            output_item checklist, fields: %i[id title card_id time_created], labels: {id: "Checklist ID"}

            if checklist.items&.any?
              puts ""
              Ui.section "Items"
              checklist.items.each do |item|
                marker = item.checked? ? "✓" : "○"
                puts "  #{marker} #{item.title} (#{item.id})"
              end
            end
          end
        end
      end

      desc "create", "Create a checklist on a card"
      option :card, type: :string, required: true, aliases: "-c", desc: "Parent card ID"
      option :title, type: :string, required: true, desc: "Checklist title"
      # Add a new checklist to a card.
      #
      # @return [void]
      def create
        handle_error do
          checklist = client.cards.create_checklist(workspace_id, options[:card], title: options[:title])
          output_item checklist, fields: %i[id title card_id time_created], labels: {id: "Checklist ID"}
        end
      end

      desc "update CHECKLIST", "Update a checklist"
      option :card, type: :string, required: true, aliases: "-c", desc: "Parent card ID"
      option :title, type: :string, required: true, desc: "New checklist title"
      # Rename an existing checklist on a card.
      #
      # @param checklist_id [String] the unique identifier of the checklist
      # @return [void]
      def update(checklist_id)
        handle_error do
          checklist = client.cards.update_checklist(
            workspace_id, options[:card], checklist_id,
            title: options[:title]
          )
          output_item checklist, fields: %i[id title card_id time_created], labels: {id: "Checklist ID"}
        end
      end

      desc "delete CHECKLIST", "Delete a checklist"
      option :card, type: :string, required: true, aliases: "-c", desc: "Parent card ID"
      # Remove a checklist and all its items from a card after confirmation.
      #
      # @param checklist_id [String] the unique identifier of the checklist
      # @return [void]
      def delete(checklist_id)
        handle_error do
          card = client.cards.find(workspace_id, options[:card])
          checklist = card.checklists&.find { |c| c.id == checklist_id }
          checklist_name = checklist&.title || checklist_id
          confirming("Delete checklist '#{checklist_name}' (#{checklist_id})?") do
            client.cards.delete_checklist(workspace_id, options[:card], checklist_id)
            output_success "Checklist '#{checklist_name}' deleted"
          end
        end
      end

      desc "add-item CHECKLIST", "Add item to a checklist"
      option :card, type: :string, required: true, aliases: "-c", desc: "Parent card ID"
      option :title, type: :string, required: true, desc: "Item title"
      option :checked, type: :boolean, default: false, desc: "Create as checked"
      # Add a new item to an existing checklist.
      #
      # @param checklist_id [String] the unique identifier of the checklist
      # @return [void]
      def add_item(checklist_id)
        handle_error do
          item = client.cards.add_checklist_item(
            workspace_id, options[:card], checklist_id,
            title: options[:title],
            checked: options[:checked]
          )
          output_item item, fields: %i[id title checked checklist_id], labels: {id: "Item ID"}
        end
      end

      desc "update-item ITEM_ID", "Update a checklist item"
      option :card, type: :string, required: true, aliases: "-c", desc: "Parent card ID"
      option :checklist, type: :string, required: true, desc: "Parent checklist ID"
      option :title, type: :string, desc: "New item title"
      option :checked, type: :boolean, desc: "Mark as checked/unchecked"
      # Update the title or checked state of a checklist item.
      #
      # @param item_id [String] the unique identifier of the item
      # @return [void]
      def update_item(item_id)
        handle_error do
          opts = symbolized_options(:title, :checked)
          item = client.cards.update_checklist_item(
            workspace_id, options[:card], options[:checklist], item_id,
            **opts
          )
          output_item item, fields: %i[id title checked checklist_id], labels: {id: "Item ID"}
        end
      end

      desc "remove-item ITEM_ID", "Delete a checklist item"
      option :card, type: :string, required: true, aliases: "-c", desc: "Parent card ID"
      option :checklist, type: :string, required: true, desc: "Parent checklist ID"
      # Remove an item from a checklist after confirmation.
      #
      # @param item_id [String] the unique identifier of the item
      # @return [void]
      def remove_item(item_id)
        handle_error do
          card = client.cards.find(workspace_id, options[:card])
          checklist = card.checklists&.find { |c| c.id == options[:checklist] }
          item = checklist&.items&.find { |i| i.id == item_id }
          item_name = item&.title || item_id
          confirming("Delete checklist item '#{item_name}' (#{item_id})?") do
            client.cards.delete_checklist_item(workspace_id, options[:card], options[:checklist], item_id)
            output_success "Checklist item '#{item_name}' deleted"
          end
        end
      end

      desc "check ITEM_ID", "Mark a checklist item as checked"
      option :card, type: :string, required: true, aliases: "-c", desc: "Parent card ID"
      option :checklist, type: :string, required: true, desc: "Parent checklist ID"
      # Mark a checklist item as completed.
      #
      # @param item_id [String] the unique identifier of the item
      # @return [void]
      def check(item_id)
        handle_error do
          item = client.cards.update_checklist_item(
            workspace_id, options[:card], options[:checklist], item_id,
            checked: true
          )
          output_item item, fields: %i[id title checked checklist_id], labels: {id: "Item ID"}
        end
      end

      desc "uncheck ITEM_ID", "Mark a checklist item as unchecked"
      option :card, type: :string, required: true, aliases: "-c", desc: "Parent card ID"
      option :checklist, type: :string, required: true, desc: "Parent checklist ID"
      # Mark a checklist item as not completed.
      #
      # @param item_id [String] the unique identifier of the item
      # @return [void]
      def uncheck(item_id)
        handle_error do
          item = client.cards.update_checklist_item(
            workspace_id, options[:card], options[:checklist], item_id,
            checked: false
          )
          output_item item, fields: %i[id title checked checklist_id], labels: {id: "Item ID"}
        end
      end
    end
  end
end
