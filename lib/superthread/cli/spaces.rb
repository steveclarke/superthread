# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for space operations.
    class Spaces < Base
      desc "list", "List all spaces"
      def list
        spaces = client.spaces.list(workspace_id)
        output_list spaces, columns: %i[id title]
      end

      desc "get SPACE", "Get space details"
      def get(space_ref)
        space = client.spaces.find(workspace_id, resolve_space(space_ref))
        output_item space, fields: %i[id title description time_created time_updated]
      end

      desc "create", "Create a new space"
      option :title, type: :string, required: true, desc: "Space title"
      option :description, type: :string, desc: "Space description"
      option :icon, type: :string, desc: "Space icon"
      def create
        space = client.spaces.create(workspace_id, **symbolized_options(:title, :description, :icon))
        output_item space
      end

      desc "update SPACE", "Update a space"
      option :title, type: :string, desc: "New title"
      option :description, type: :string, desc: "New description"
      option :icon, type: :string, desc: "New icon"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      def update(space_ref)
        space = client.spaces.update(workspace_id, resolve_space(space_ref),
          **symbolized_options(:title, :description, :icon, :archived))
        output_item space
      end

      desc "delete SPACE", "Delete a space"
      def delete(space_ref)
        resolved = resolve_space(space_ref)
        client.spaces.destroy(workspace_id, resolved)
        output_success "Space #{space_ref} deleted"
      end

      desc "add_member SPACE USER", "Add a member to a space"
      option :role, type: :string, desc: "Member role"
      def add_member(space_ref, user_ref)
        space_resolved = resolve_space(space_ref)
        user_resolved = resolve_user(user_ref)
        client.spaces.add_member(workspace_id, space_resolved, user_id: user_resolved, role: options[:role])
        output_success "Added #{user_ref} to space #{space_ref}"
      end

      desc "remove_member SPACE USER", "Remove a member from a space"
      def remove_member(space_ref, user_ref)
        handle_error do
          space_resolved = resolve_space(space_ref)
          user_resolved = resolve_user(user_ref)
          client.spaces.remove_member(workspace_id, space_resolved, user_resolved)
          output_success "Removed #{user_ref} from space #{space_ref}"
        end
      end
    end
  end
end
