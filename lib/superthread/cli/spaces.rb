# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for space operations.
    class Spaces < Base
      desc 'list', 'List all spaces'
      def list
        spaces = client.spaces.list(workspace_id)
        output_list spaces, columns: %i[id title]
      end

      desc 'get SPACE_ID', 'Get space details'
      def get(space_id)
        space = client.spaces.find(workspace_id, space_id)
        output_item space, fields: %i[id title description time_created time_updated]
      end

      desc 'create', 'Create a new space'
      option :title, type: :string, required: true, desc: 'Space title'
      option :description, type: :string, desc: 'Space description'
      option :icon, type: :string, desc: 'Space icon'
      def create
        space = client.spaces.create(workspace_id, **symbolized_options(:title, :description, :icon))
        output_item space
      end

      desc 'update SPACE_ID', 'Update a space'
      option :title, type: :string, desc: 'New title'
      option :description, type: :string, desc: 'New description'
      option :icon, type: :string, desc: 'New icon'
      option :archived, type: :boolean, desc: 'Archive/unarchive'
      def update(space_id)
        space = client.spaces.update(workspace_id, space_id,
                                     **symbolized_options(:title, :description, :icon, :archived))
        output_item space
      end

      desc 'delete SPACE_ID', 'Delete a space'
      def delete(space_id)
        client.spaces.destroy(workspace_id, space_id)
        output_success "Space #{space_id} deleted"
      end

      desc 'add_member SPACE_ID USER_ID', 'Add a member to a space'
      option :role, type: :string, desc: 'Member role'
      def add_member(space_id, user_id)
        client.spaces.add_member(workspace_id, space_id, user_id: user_id, role: options[:role])
        output_success "Added #{user_id} to space #{space_id}"
      end

      desc 'remove_member SPACE_ID MEMBER_ID', 'Remove a member from a space'
      def remove_member(space_id, member_id)
        client.spaces.remove_member(workspace_id, space_id, member_id)
        output_success "Removed #{member_id} from space #{space_id}"
      end
    end
  end
end
