# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing Superthread tags.
    #
    # Tags are labels that can be applied to cards for categorization
    # and filtering. Each tag has a name and color.
    class Tags < Base
      desc "list", "List available tags"
      option :space, type: :string, aliases: "-s", desc: "Space to filter by (ID or name)"
      option :all, type: :boolean, desc: "Include unused tags"
      # Lists all available tags in the workspace.
      #
      # @return [void]
      def list
        handle_error do
          opts = symbolized_options(:all)
          opts[:project_id] = space_id if options[:space]
          tags = client.cards.tags(workspace_id, **opts)
          output_list tags, columns: %i[id name color total_cards], headers: {id: "TAG_ID"}
        end
      end

      desc "create", "Create a new tag"
      option :name, type: :string, required: true, desc: "Tag name"
      option :color, type: :string, required: true, desc: "Tag color (hex)"
      option :space, type: :string, aliases: "-s", desc: "Space to create tag in (ID or name)"
      # Creates a new tag in the workspace with a name and color.
      #
      # @return [void]
      def create
        opts = symbolized_options(:name, :color)
        opts[:space_id] = space_id if options[:space]
        tag = client.tags.create(workspace_id, **opts)
        output_item tag, fields: %i[id name color], labels: {id: "Tag ID"}
      end

      desc "update TAG", "Update a tag"
      option :name, type: :string, desc: "New name"
      option :color, type: :string, desc: "New color (hex)"
      # Updates an existing tag's name or color.
      #
      # @param tag_ref [String] tag identifier (ID or name)
      # @return [void]
      def update(tag_ref)
        handle_error do
          tag_id = resolve_tag(tag_ref)
          begin
            tag = client.tags.update(workspace_id, tag_id, **symbolized_options(:name, :color))
          rescue Superthread::ForbiddenError, Superthread::NotFoundError
            raise Thor::Error, "Tag not found: '#{tag_ref}'. Use 'suth tags list' to see available tags."
          end
          output_item tag, labels: {id: "Tag ID"}
        end
      end

      desc "delete TAG", "Delete a tag"
      # Deletes a tag after confirmation.
      #
      # @param tag_ref [String] tag identifier (ID or name)
      # @return [void]
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
      #
      # @param ref [String] the tag ID or name to find
      # @return [Superthread::Models::Tag] the matching tag object
      # @raise [Thor::Error] if no matching tag is found
      def find_tag(ref)
        tags = client.cards.tags(workspace_id, all: true)
        tag = tags.find { |t| t.id == ref || t.name&.downcase == ref.downcase }
        raise Thor::Error, "Tag not found: '#{ref}'. Use 'st tags list' to see available tags." unless tag
        tag
      end
    end
  end
end
