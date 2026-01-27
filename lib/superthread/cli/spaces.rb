# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing Superthread spaces.
    #
    # Spaces are containers that organize boards, pages, and other content
    # within a workspace. This class provides commands to list, create,
    # update, and delete spaces, as well as manage space membership.
    class Spaces < Base
      desc "list", "List all spaces"
      # Lists all spaces in the current workspace.
      #
      # @return [void]
      def list
        spaces = client.spaces.list(workspace_id)
        output_list spaces, columns: %i[id title]
      end

      desc "get SPACE", "Get space details"
      # Retrieves and displays details for a specific space.
      #
      # @param space_ref [String] space identifier (ID or name)
      # @return [void]
      def get(space_ref)
        handle_error do
          resolved_space_id = resolve_space(space_ref)
          space = client.spaces.find(workspace_id, resolved_space_id)
          output_item space, fields: %i[id title description time_created time_updated]
        end
      end

      desc "create", "Create a new space"
      option :title, type: :string, required: true, desc: "Space title"
      option :description, type: :string, desc: "Space description"
      option :icon, type: :string, desc: "Space icon"
      # Creates a new space in the current workspace.
      #
      # @return [void]
      def create
        space = client.spaces.create(workspace_id, **symbolized_options(:title, :description, :icon))
        output_item space
      end

      desc "update SPACE", "Update a space"
      option :title, type: :string, desc: "New title"
      option :description, type: :string, desc: "New description"
      option :icon, type: :string, desc: "New icon"
      # Updates an existing space's properties.
      #
      # @param space_ref [String] space identifier (ID or name)
      # @return [void]
      def update(space_ref)
        space = client.spaces.update(workspace_id, resolve_space(space_ref),
          **symbolized_options(:title, :description, :icon))
        output_item space
      end

      desc "delete SPACE", "Delete a space"
      # Deletes a space after confirmation.
      #
      # @param space_ref [String] space identifier (ID or name)
      # @return [void]
      def delete(space_ref)
        handle_error do
          space = client.spaces.find(workspace_id, resolve_space(space_ref))
          confirming("Delete space '#{space.title}' (#{space.id})?") do
            client.spaces.destroy(workspace_id, space.id)
            output_success "Space '#{space.title}' deleted"
          end
        end
      end

      desc "add_member SPACE USERS", "Add member(s) to a space (comma-separated)"
      option :role, type: :string, desc: "Member role"
      # Adds one or more users as members of a space with an optional role.
      #
      # @param space_ref [String] space identifier (ID or name)
      # @param user_refs [String] comma-separated user IDs, names, or emails
      # @return [void]
      def add_member(space_ref, user_refs)
        handle_error do
          space_resolved = resolve_space(space_ref)
          users = user_refs.split(",").map(&:strip)
          users.each do |user_ref|
            user_resolved = resolve_user(user_ref)
            client.spaces.add_member(workspace_id, space_resolved, user_id: user_resolved, role: options[:role])
          end
          output_success "Added #{users.size} user(s) to space #{space_ref}"
        end
      end

      desc "remove_member SPACE USERS", "Remove member(s) from a space (comma-separated)"
      # Removes one or more users from a space.
      #
      # @param space_ref [String] space identifier (ID or name)
      # @param user_refs [String] comma-separated user IDs, names, or emails
      # @return [void]
      def remove_member(space_ref, user_refs)
        handle_error do
          space_resolved = resolve_space(space_ref)
          users = user_refs.split(",").map(&:strip)
          users.each do |user_ref|
            user_resolved = resolve_user(user_ref)
            client.spaces.remove_member(workspace_id, space_resolved, user_resolved)
          end
          output_success "Removed #{users.size} user(s) from space #{space_ref}"
        end
      end
    end
  end
end
