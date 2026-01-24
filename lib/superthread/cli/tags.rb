# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for tag operations.
    class Tags < Base
      desc "create", "Create a new tag"
      option :name, type: :string, required: true, desc: "Tag name"
      option :color, type: :string, required: true, desc: "Tag color (hex)"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name)"
      def create
        opts = symbolized_options(:name, :color)
        opts[:space_id] = space_id if options[:space]
        tag = client.tags.create(workspace_id, **opts)
        output_item tag, fields: %i[id name color]
      end

      desc "update TAG", "Update a tag"
      option :name, type: :string, desc: "New name"
      option :color, type: :string, desc: "New color (hex)"
      def update(tag_ref)
        tag_id = resolve_tag(tag_ref)
        tag = client.tags.update(workspace_id, tag_id, **symbolized_options(:name, :color))
        output_item tag
      end

      desc "delete TAG", "Delete a tag"
      option :force, type: :boolean, aliases: "-f", desc: "Skip confirmation"
      def delete(tag_ref)
        handle_error do
          tag = find_tag(tag_ref)
          confirming("Delete tag '#{tag.name}' (#{tag.id})?") do
            client.tags.destroy(workspace_id, tag.id)
            output_success "Tag '#{tag.name}' deleted"
          end
        end
      end

      private

      # Find tag by ID or name, returning the full tag object.
      def find_tag(ref)
        tags = client.cards.tags(workspace_id, all: true)
        tag = tags.find { |t| t.id == ref || t.name&.downcase == ref.downcase }
        raise Thor::Error, "Tag not found: '#{ref}'. Use 'st cards tags' to see available tags." unless tag
        tag
      end
    end
  end
end
